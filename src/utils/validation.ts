export const isValidEmail = (email: string): boolean => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

export const isStrongPassword = (value: string): boolean => value.length >= 6;

export const isValidId = (id: unknown): id is number => {
  if (id === null || id === undefined) return false;
  if (typeof id === "string" && (id.trim() === "" || id.trim() === "undefined" || id.trim() === "null")) return false;
  const num = typeof id === "number" ? id : Number(id);
  return Number.isFinite(num) && num > 0;
};
