import React from "react";
import useFormValidation from "../../hooks/useFormValidation";
import ErrorMessage from "../../components/ErrorMessage";

export const SignupForm: React.FC = () => {
  const {
    values,
    errors,
    touched,
    isSubmitting,
    serverError,
    successMessage,
    isValid,
    handleChange,
    handleBlur,
    handleSubmit,
  } = useFormValidation();

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        handleSubmit();
      }}
      noValidate
      className="space-y-4 max-w-md"
    >
      {serverError && (
        <ErrorMessage
          message={serverError}
          onRetry={() => handleSubmit()}
          actionLabel={serverError.includes("connect") ? "Se connecter" : undefined}
        />
      )}

      {successMessage && (
        <div className="text-green-700 bg-green-50 p-2 rounded">{successMessage}</div>
      )}

      <div>
        <label className="block text-sm font-medium">Prénom</label>
        <input
          name="firstName"
          value={values.firstName}
          onChange={handleChange}
          onBlur={handleBlur}
          className={`mt-1 block w-full rounded border px-3 py-2 ${
            errors.firstName
              ? "border-red-500"
              : values.firstName
                ? "border-green-400"
                : "border-gray-200"
          }`}
        />
        {(touched.firstName || values.firstName) && errors.firstName && (
          <p className="text-sm text-red-600 mt-1">{errors.firstName}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium">Nom</label>
        <input
          name="lastName"
          value={values.lastName}
          onChange={handleChange}
          onBlur={handleBlur}
          className={`mt-1 block w-full rounded border px-3 py-2 ${
            errors.lastName
              ? "border-red-500"
              : values.lastName
                ? "border-green-400"
                : "border-gray-200"
          }`}
        />
        {(touched.lastName || values.lastName) && errors.lastName && (
          <p className="text-sm text-red-600 mt-1">{errors.lastName}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium">Téléphone</label>
        <input
          name="phone"
          value={values.phone}
          onChange={handleChange}
          onBlur={handleBlur}
          className={`mt-1 block w-full rounded border px-3 py-2 ${
            errors.phone ? "border-red-500" : values.phone ? "border-green-400" : "border-gray-200"
          }`}
        />
        {(touched.phone || values.phone) && errors.phone && (
          <p className="text-sm text-red-600 mt-1">{errors.phone}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium">Email</label>
        <input
          name="email"
          type="email"
          value={values.email}
          onChange={handleChange}
          onBlur={handleBlur}
          className={`mt-1 block w-full rounded border px-3 py-2 ${
            errors.email ? "border-red-500" : values.email ? "border-green-400" : "border-gray-200"
          }`}
        />
        {(touched.email || values.email) && errors.email && (
          <p className="text-sm text-red-600 mt-1">{errors.email}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium">Mot de passe</label>
        <input
          name="password"
          type="password"
          value={values.password}
          onChange={handleChange}
          onBlur={handleBlur}
          className={`mt-1 block w-full rounded border px-3 py-2 ${
            errors.password
              ? "border-red-500"
              : values.password
                ? "border-green-400"
                : "border-gray-200"
          }`}
        />
        {(touched.password || values.password) && errors.password && (
          <p className="text-sm text-red-600 mt-1">{errors.password}</p>
        )}
      </div>

      <div>
        <button
          type="submit"
          disabled={!isValid || isSubmitting}
          className={`w-full py-2 px-4 rounded text-white ${!isValid || isSubmitting ? "bg-gray-400" : "bg-blue-600"}`}
        >
          {isSubmitting ? "En cours..." : "Sign up"}
        </button>
      </div>
    </form>
  );
};

export default SignupForm;
