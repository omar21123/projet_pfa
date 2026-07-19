// types/admin.ts

export interface AdminUser {
  public_id: string;
  first_name: string;
  last_name: string;
  display_name: string;
  email: string;
  phone_number: string | null;
  avatar_url: string | null;
  last_login_at: string | null;
}

export interface AdminProfileDetails {
  employee_number: string;
  cin: string;
  position: string;
  status: number;
  identity_verified: boolean;
  hire_date: string;
}

export interface AdminProfileResponse {
  success: boolean;
  data: {
    user: AdminUser;
    admin_profile: AdminProfileDetails;
  };
}
