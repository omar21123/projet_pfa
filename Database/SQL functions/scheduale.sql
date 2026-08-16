-- ====================================================
-- Make sure the MySQL event scheduler is actually running.
-- This is a server-level setting; SET GLOBAL only persists
-- until MySQL restarts, so also add
-- `event_scheduler = ON` to your my.cnf for it to survive reboots.
-- ====================================================
SET GLOBAL event_scheduler = ON;

-- Check it's on:
-- SHOW VARIABLES LIKE 'event_scheduler';

DROP EVENT IF EXISTS EVT_ReleaseMaturedBankAccountHolds;

DELIMITER $$

CREATE EVENT EVT_ReleaseMaturedBankAccountHolds
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN
    DECLARE v_Success        BOOLEAN;
    DECLARE v_Message         VARCHAR(255);
    DECLARE v_ReleasedCount    INT;

    CALL SP_ReleaseMaturedBankAccountHolds(v_Success, v_Message, v_ReleasedCount);

    INSERT INTO SPErrorLogs (ProcedureName, ErrorMessage, CreatedAt)
    VALUES (
        'EVT_ReleaseMaturedBankAccountHolds',
        CONCAT('success=', v_Success, ' released=', v_ReleasedCount, ' message=', v_Message),
        NOW()
    );
END$$

DELIMITER ;
-- See all events and their next scheduled run
SHOW EVENTS;

-- Or more detail:
SELECT EVENT_NAME, STATUS, INTERVAL_VALUE, INTERVAL_FIELD, LAST_EXECUTED
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = DATABASE();

-- Pause it without dropping it
ALTER EVENT EVT_ReleaseMaturedBankAccountHolds DISABLE;

-- Resume it
ALTER EVENT EVT_ReleaseMaturedBankAccountHolds ENABLE;

-- Run it manually right now, outside the schedule, to test
CALL SP_ReleaseMaturedBankAccountHolds(@success, @message, @count);
SELECT @success, @message, @count;