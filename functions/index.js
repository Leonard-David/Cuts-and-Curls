/**
 * Firebase Cloud Functions for VerveBook (SheerSync)
 * --------------------------------------------------
 * - Sends OTP via email for verification
 * - Creates notification documents for barbers on appointment events
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
require("dotenv").config();

// ✅ Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

/* =========================================================
   EMAIL OTP FUNCTION
   ========================================================= */

// 🟢 Use Firebase config variables for deployment
// 👉 Run this in terminal before deploy:
// firebase functions:config:set gmail.email="YOUR_EMAIL@gmail.com" gmail.password="YOUR_APP_PASSWORD"

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_EMAIL || functions.config().gmail.email,
    pass: process.env.GMAIL_PASSWORD || functions.config().gmail.password,
  },
});

// Helper: Generate 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Helper: Get current year for footer
function getCurrentYear() {
  return new Date().getFullYear();
}

/**
 * ✅ Cloud Function: sendEmailOTP
 * Sends a verification code to the user's email
 */
exports.sendEmailOTP = functions.https.onCall(async (data, context) => {
  const { email, userName = "User" } = data;

  if (!email) {
    throw new functions.https.HttpsError("invalid-argument", "Email is required");
  }

  const otp = generateOTP();
  const expiry = Date.now() + 10 * 60 * 1000; // expires in 10 minutes
  const currentYear = getCurrentYear();

  // Store OTP temporarily in Firestore
  await db.collection("email_otps").doc(email).set({
    otp,
    expiry,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Prepare Email Content
  const emailHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<title>Verify Your VerveBook Account</title>
<style>
body {
  font-family: 'Segoe UI', Arial, sans-serif;
  background-color: #f6f9fc;
  margin: 0; padding: 0;
  color: #333;
}
.email-container {
  max-width: 600px;
  background: #fff;
  margin: 20px auto;
  border-radius: 12px;
  box-shadow: 0 4px 8px rgba(0,0,0,0.05);
  overflow: hidden;
}
.header {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  text-align: center;
  padding: 25px 20px;
}
.otp {
  font-size: 36px;
  letter-spacing: 8px;
  color: #2d3748;
  background: #f8fafc;
  border: 2px dashed #e2e8f0;
  border-radius: 8px;
  padding: 20px;
  display: inline-block;
  margin: 16px 0;
}
.footer {
  background: #f8f9fa;
  text-align: center;
  padding: 20px;
  font-size: 12px;
  color: #666;
}
</style>
</head>
<body>
  <div class="email-container">
    <div class="header">
      <h2>VerveBook Verification Code</h2>
      <p>Seamless Synchronization, Elevated Experience</p>
    </div>
    <div style="padding: 30px;">
      <p>Hello <strong>${userName}</strong>,</p>
      <p>Your verification code is:</p>
      <div class="otp">${otp}</div>
      <p>This code expires in <strong>10 minutes</strong>.</p>
      <p>Do not share this code with anyone.</p>
    </div>
    <div class="footer">
      <p>© ${currentYear} VerveBook Technologies. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
`;

  const mailOptions = {
    from: {
      name: "VerveBook Security",
      address: process.env.GMAIL_EMAIL || functions.config().gmail.email,
    },
    to: email,
    subject: "Your VerveBook Verification Code",
    html: emailHtml,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`✅ OTP sent to ${email}`);
    return { success: true, message: `OTP sent to ${email}` };
  } catch (error) {
    console.error("❌ Failed to send OTP:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to send verification email. Please try again."
    );
  }
});

/**
 * ✅ Test your email configuration
 */
exports.testEmailConfiguration = functions.https.onCall(async () => {
  try {
    await transporter.verify();
    return {
      success: true,
      message: "Email service is properly configured and ready",
      service: "Gmail SMTP",
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    throw new functions.https.HttpsError(
      "internal",
      `Email configuration error: ${error.message}`
    );
  }
});

/* =========================================================
   FIRESTORE TRIGGERS: APPOINTMENTS + NOTIFICATIONS
   ========================================================= */

// 🔔 Trigger: new appointment created
exports.onAppointmentCreated = functions.firestore
  .document("appointments/{appointmentId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const barberId = data.barberId;
    const clientName = data.clientName || "Client";
    const service = data.service || "Service";

    await db.collection("notifications").add({
      userId: barberId,
      type: "appointment",
      title: "New Appointment Booked",
      body: `${clientName} booked a ${service}`,
      meta: { appointmentId: context.params.appointmentId },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`📅 New appointment notification for ${barberId}`);
  });

// 🔁 Trigger: appointment status updated
exports.onAppointmentUpdated = functions.firestore
  .document("appointments/{appointmentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return; // Skip if no change

    const barberId = after.barberId;
    const clientName = after.clientName || "Client";
    let message = "";

    if (after.status === "completed") {
      message = `Appointment with ${clientName} was completed.`;
    } else if (after.status === "cancelled") {
      message = `Appointment with ${clientName} was cancelled.`;
    } else {
      message = `Appointment with ${clientName} updated to ${after.status}.`;
    }

    await db.collection("notifications").add({
      userId: barberId,
      type: "status",
      title: "Appointment Update",
      body: message,
      meta: { appointmentId: context.params.appointmentId },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`📢 Status update notification sent to ${barberId}`);
  });
