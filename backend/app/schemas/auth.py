from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class UserRegisterIn(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2)
    role: str = Field(default="CITIZEN", description="CITIZEN, TECHNICIAN, ENGINEER, AUTHORITY, ADMIN")
    zone: Optional[str] = "Sector 1"
    staff_auth_code: Optional[str] = Field(None, description="Department authorization code required for Staff roles")


class UserLoginIn(BaseModel):
    email: str
    password: str


class ForgotPasswordIn(BaseModel):
    email: str = Field(..., description="Registered email address")


class ResetPasswordIn(BaseModel):
    email: str = Field(..., description="Registered email address")
    token: str = Field(..., description="Reset verification code/token")
    new_password: str = Field(..., min_length=6, description="New secure password")


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    full_name: str
    role: str
    zone: str
    is_active: bool
    created_at: Optional[datetime] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut
