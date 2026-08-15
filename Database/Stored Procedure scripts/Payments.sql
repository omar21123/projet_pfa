DROP PROCEDURE IF EXISTS SP_PayFromOrder;

DELIMITER $$

CREATE PROCEDURE SP_PayFromOrder (
    IN  v_OrderID            INT,
    IN  v_PaymentMethodID    INT,
    IN  v_TransactionID      VARCHAR(150),
    IN  v_ProviderReference  VARCHAR(150),
    OUT v_PaymentID          INT,
    OUT v_Success            BOOLEAN,
    OUT v_Message            VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_OrderTotal      DECIMAL(12,2) DEFAULT NULL;
    DECLARE v_Currency        CHAR(3) DEFAULT NULL;
    DECLARE v_ExistingPayment INT DEFAULT 0;

    DECLARE v_VendorProfileID INT;
    DECLARE v_VendorAmount    DECIMAL(12,2);
    DECLARE v_BankAccountID   INT;
    DECLARE v_Done            TINYINT DEFAULT 0;

    -- Group directly on OrderItems.VendorProfileID (already stored there),
    -- no need to join VendorProfiles just to get the same ID back.
    DECLARE vendor_cursor CURSOR FOR
        SELECT oi.VendorProfileID, SUM(oi.Total) AS VendorAmount
        FROM OrderItems oi
        WHERE oi.OrderID = v_OrderID
        GROUP BY oi.VendorProfileID;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_Done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        -- Rollback FIRST, so the log insert below runs outside the
        -- failed transaction and actually survives / commits.
        ROLLBACK;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_PayFromOrder',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT(
                'OrderID', v_OrderID,
                'PaymentMethodID', v_PaymentMethodID,
                'TransactionID', v_TransactionID
            )
        );

        SET v_Success   = FALSE;
        SET v_PaymentID = NULL;
        SET v_Message   = 'Une erreur est survenue lors du traitement du paiement.';
    END;

    SET v_Success   = FALSE;
    SET v_Message   = '';
    SET v_PaymentID = NULL;

    -- 1) Order must exist
    SELECT Total, Currency
    INTO v_OrderTotal, v_Currency
    FROM Orders
    WHERE OrderID = v_OrderID;

    IF v_OrderTotal IS NULL THEN
        SET v_Message = 'Commande introuvable.';
        LEAVE main_block;
    END IF;

    IF v_OrderTotal <= 0 THEN
        SET v_Message = 'Le montant de la commande est invalide.';
        LEAVE main_block;
    END IF;

    -- 2) Payment method must exist
    IF NOT EXISTS (SELECT 1 FROM PaymentMethods WHERE PaymentMethodID = v_PaymentMethodID) THEN
        SET v_Message = 'Méthode de paiement invalide.';
        LEAVE main_block;
    END IF;

    -- 3) Prevent double payment on the same order (only one successful payment allowed)
    SELECT COUNT(*) INTO v_ExistingPayment
    FROM Payments
    WHERE OrderID = v_OrderID
      AND Status = 1;

    IF v_ExistingPayment > 0 THEN
        SET v_Message = 'Cette commande a déjà été payée.';
        LEAVE main_block;
    END IF;

    -- 4) Order must actually contain items to split money across vendors
    IF NOT EXISTS (SELECT 1 FROM OrderItems WHERE OrderID = v_OrderID) THEN
        SET v_Message = 'Cette commande ne contient aucun article.';
        LEAVE main_block;
    END IF;

    START TRANSACTION;

    -- 5) Record the payment (Status = 1 = paid, captured now)
    INSERT INTO Payments (
        OrderID, PaymentMethodID, Amount, Currency,
        TransactionID, ProviderReference, Status, PaidAt
    ) VALUES (
        v_OrderID, v_PaymentMethodID, v_OrderTotal, v_Currency,
        v_TransactionID, v_ProviderReference, 1, NOW()
    );

    SET v_PaymentID = LAST_INSERT_ID();

    -- 6) Split the payment across each vendor (by VendorProfileID) represented in this order,
    --    creating their BankAccount on the fly if it doesn't exist yet,
    --    and freezing each vendor's share for 14 days.
    OPEN vendor_cursor;

    vendor_loop: LOOP
        FETCH vendor_cursor INTO v_VendorProfileID, v_VendorAmount;

        IF v_Done = 1 THEN
            LEAVE vendor_loop;
        END IF;

        SELECT BankAccountID INTO v_BankAccountID
        FROM BankAccounts
        WHERE VendorProfileID = v_VendorProfileID
        LIMIT 1;

        IF v_BankAccountID IS NULL THEN
            INSERT INTO BankAccounts (
                VendorProfileID, CurrentBalance, WithdrawableBalance,
                PendingBalance, CurrencyCode, IsLocked
            ) VALUES (
                v_VendorProfileID, 0.00, 0.00, 0.00, v_Currency, 0
            );

            SET v_BankAccountID = LAST_INSERT_ID();
        END IF;

        UPDATE BankAccounts
        SET CurrentBalance = CurrentBalance + v_VendorAmount,
            PendingBalance  = PendingBalance + v_VendorAmount,
            UpdatedAt       = NOW()
        WHERE BankAccountID = v_BankAccountID;

        INSERT INTO BankAccountHolds (
            BankAccountID, OrderID, PaymentID, Amount, ReleaseAt, Status
        ) VALUES (
            v_BankAccountID, v_OrderID, v_PaymentID, v_VendorAmount,
            DATE_ADD(NOW(), INTERVAL 14 DAY), 0
        );

        SET v_BankAccountID = NULL;
    END LOOP;

    CLOSE vendor_cursor;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = 'Paiement effectué avec succès.';
END main_block $$

DELIMITER ;

DROP PROCEDURE IF EXISTS SP_ReleaseMaturedHolds;

DELIMITER $$

CREATE PROCEDURE SP_ReleaseMaturedHolds (
    OUT v_ReleasedCount       INT,
    OUT v_ReleasedAmount      DECIMAL(14,2),
    OUT v_SkippedLockedCount  INT,
    OUT v_Success             BOOLEAN,
    OUT v_Message             VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_Done          TINYINT DEFAULT 0;
    DECLARE v_HoldID        INT;
    DECLARE v_BankAccountID INT;
    DECLARE v_Amount        DECIMAL(12,2);
    DECLARE v_IsLocked      TINYINT;

    -- FOR UPDATE locks the matured hold rows for the duration of the
    -- transaction, so a second overlapping cron run can't grab and
    -- release the same holds twice.
    DECLARE holds_cursor CURSOR FOR
        SELECT h.HoldID, h.BankAccountID, h.Amount, ba.IsLocked
        FROM BankAccountHolds h
        INNER JOIN BankAccounts ba ON ba.BankAccountID = h.BankAccountID
        WHERE h.Status = 0
          AND h.ReleaseAt <= NOW()
        ORDER BY h.HoldID
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_Done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p_sqlstate = RETURNED_SQLSTATE,
            @p_errno    = MYSQL_ERRNO,
            @p_message  = MESSAGE_TEXT;

        INSERT INTO SPErrorLogs (ProcedureName, ErrorSQLState, ErrorNumber, ErrorMessage, ContextData)
        VALUES (
            'SP_ReleaseMaturedHolds',
            @p_sqlstate,
            @p_errno,
            @p_message,
            JSON_OBJECT('RunAt', NOW())
        );

        ROLLBACK;
        SET v_Success            = FALSE;
        SET v_Message             = 'Une erreur est survenue lors de la libération des fonds.';
        SET v_ReleasedCount       = 0;
        SET v_ReleasedAmount      = 0.00;
        SET v_SkippedLockedCount  = 0;
    END;

    SET v_Success            = FALSE;
    SET v_Message            = '';
    SET v_ReleasedCount      = 0;
    SET v_ReleasedAmount     = 0.00;
    SET v_SkippedLockedCount = 0;

    START TRANSACTION;

    OPEN holds_cursor;

    holds_loop: LOOP
        FETCH holds_cursor INTO v_HoldID, v_BankAccountID, v_Amount, v_IsLocked;

        IF v_Done = 1 THEN
            LEAVE holds_loop;
        END IF;

        IF v_IsLocked = 1 THEN
            -- Locked accounts keep their funds frozen until manually
            -- unlocked; the hold stays Status = 0 and is retried on
            -- the next scheduled run.
            SET v_SkippedLockedCount = v_SkippedLockedCount + 1;
        ELSE
            UPDATE BankAccounts
            SET PendingBalance      = PendingBalance - v_Amount,
                WithdrawableBalance = WithdrawableBalance + v_Amount,
                UpdatedAt           = NOW()
            WHERE BankAccountID = v_BankAccountID;

            UPDATE BankAccountHolds
            SET Status     = 1,
                ReleasedAt = NOW()
            WHERE HoldID = v_HoldID;

            SET v_ReleasedCount  = v_ReleasedCount + 1;
            SET v_ReleasedAmount = v_ReleasedAmount + v_Amount;
        END IF;
    END LOOP;

    CLOSE holds_cursor;

    COMMIT;

    SET v_Success = TRUE;
    SET v_Message = CONCAT(
        v_ReleasedCount, ' dépôt(s) libéré(s) pour un total de ', v_ReleasedAmount, ' ',
        IF(v_SkippedLockedCount > 0, CONCAT('(', v_SkippedLockedCount, ' compte(s) verrouillé(s) ignoré(s)).'), '.')
    );
END main_block $$

DELIMITER ;