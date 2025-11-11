<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Welcome to My Kanisa App</title>
</head>
<body style="margin:0; padding:0; background-color:#e8eef6; font-family:'Segoe UI', Arial, sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="max-width:650px; margin:auto; background:#ffffff; border-radius:12px; overflow:hidden; box-shadow:0 6px 20px rgba(0,0,0,0.1);">

    <!-- Header -->
    <tr>
      <td align="center" style="background:linear-gradient(135deg, #001f3f, #003366); padding:45px 25px;">
        <h1 style="margin:0; color:#ffffff; font-size:30px; letter-spacing:0.5px;">
          Welcome to <span style="color:#4ea8de;">P.C.E.A My Kanisa App</span>
        </h1>
        <p style="margin:10px 0 0; color:#cde7ff; font-size:16px;">
          Your spiritual journey begins here
        </p>
      </td>
    </tr>

    <!-- Body -->
    <tr>
      <td style="padding:35px 30px; color:#1e293b; font-size:15px; line-height:1.7;">
        <p style="font-size:16px; margin-bottom:16px;">
          Dear <strong style="color:#003366;">{{ $member->full_name }}</strong>,
        </p>

        <p style="margin-bottom:20px;">
          We are delighted to welcome you to the <strong>My Kanisa App</strong> family!  
          Your presence enriches our community of faith and fellowship. Below are your membership details:
        </p>

        <!-- Info Card -->
        <table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f5fb; border:1px solid #cbd5e1; border-radius:10px; margin:20px 0;">
          <tr><td style="padding:10px 15px;"><strong>My Kanisa Number:</strong> {{ $member->e_kanisa_number }}</td></tr>
          <tr><td style="padding:10px 15px;"><strong>Presbytery:</strong> {{ $member->presbytery }}</td></tr>
          <tr><td style="padding:10px 15px;"><strong>Parish:</strong> {{ $member->parish }}</td></tr>
          <tr><td style="padding:10px 15px;"><strong>Congregation:</strong> {{ $member->congregation }}</td></tr>
          <tr><td style="padding:10px 15px;"><strong>Email:</strong> {{ $member->email }}</td></tr>
          <tr><td style="padding:10px 15px;"><strong>Telephone:</strong> {{ $member->telephone }}</td></tr>
        </table>

        <p style="margin-bottom:25px;">
          May your journey with us be filled with faith, growth, and blessings.  
          We look forward to walking with you in service and community.
        </p>

        <!-- Call-to-Action Button -->
        <div style="text-align:center; margin-top:25px;">
          <a href="https://ekanisa.example.com/login"
             style="background:#003366; color:#ffffff; text-decoration:none; padding:14px 32px; border-radius:30px; font-size:15px; display:inline-block; font-weight:500; box-shadow:0 4px 10px rgba(0,0,0,0.1);">
            Go to MyKanisa App
          </a>
        </div>
      </td>
    </tr>

    <!-- Divider -->
    <tr>
      <td style="padding:0 30px;">
        <hr style="border:none; border-top:1px solid #e2e8f0; margin:0;">
      </td>
    </tr>

    <!-- Footer -->
    <tr>
      <td align="center" style="background:#f1f5fb; padding:22px;">
        <p style="margin:0; font-size:13px; color:#475569;">
          &copy; {{ date('Y') }} <strong>My Kanisa App</strong> — All Rights Reserved.<br>
          <span style="font-size:12px; color:#64748b;">“Building Faith Through Fellowship.”</span>
        </p>
      </td>
    </tr>

  </table>
</body>
</html>
