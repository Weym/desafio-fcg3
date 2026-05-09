from pydantic import BaseModel, EmailStr, Field


class RequestCodePayload(BaseModel):
    email: EmailStr
    channel: str = Field(default="email", pattern="^email$")  # SMS deferred


class RequestCodeResponse(BaseModel):
    message: str = "Codigo enviado"  # D-08 generic response
    expires_in: int  # OTP_EXPIRY_SECONDS


class VerifyCodePayload(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6, pattern="^[0-9]{6}$")


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # access_token TTL seconds


class RefreshPayload(BaseModel):
    refresh_token: str


class MeResponse(BaseModel):
    id: str
    email: EmailStr
    name: str
    role: str  # 'student' | 'staff'
