<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Password Reset Code</title>
    <style>
        body { font-family: Arial, sans-serif; }
    </style>
</head>
<body>
    <p>We received a request to reset your password.</p>
    <p>Your verification code is:</p>
    <h2 style="letter-spacing: 4px;">{{ $code }}</h2>
    <p>This code will expire in 15 minutes.</p>
    <p>If you did not request this, you can ignore this email.</p>
</body>
</html>


