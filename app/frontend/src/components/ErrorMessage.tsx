import React from "react";

type Props = {
  message?: string | null;
  className?: string;
  onRetry?: () => void;
  actionLabel?: string;
  onAction?: () => void;
};

export const ErrorMessage: React.FC<Props> = ({
  message,
  className = "",
  onRetry,
  actionLabel,
  onAction,
}) => {
  if (!message) return null;
  return (
    <div className={`text-sm text-red-600 bg-red-50 p-2 rounded ${className}`} role="alert">
      <div>{message}</div>
      <div className="mt-2 flex gap-2">
        {onRetry && (
          <button type="button" onClick={onRetry} className="text-xs text-red-700 underline">
            Réessayer
          </button>
        )}
        {actionLabel && onAction && (
          <button type="button" onClick={onAction} className="text-xs text-red-700 underline">
            {actionLabel}
          </button>
        )}
      </div>
    </div>
  );
};

export default ErrorMessage;
