/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

// Trigger: when a new appointment is created
exports.onAppointmentCreated = functions.firestore
  .document("appointments/{appointmentId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const appointmentId = context.params.appointmentId;

    const barberId = data.barberId;
    const clientName = data.clientName || "Client";
    const service = data.service || "Service";

    await db.collection("notifications").add({
      userId: barberId,
      type: "appointment",
      title: "New Appointment Booked",
      body: `${clientName} booked a ${service}`,
      meta: { appointmentId },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Notification sent to barber: ${barberId}`);
  });

// Trigger: when appointment status changes
exports.onAppointmentUpdated = functions.firestore
  .document("appointments/{appointmentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const appointmentId = context.params.appointmentId;

    if (before.status !== after.status) {
      const barberId = after.barberId;
      let message = "";

      if (after.status === "completed") {
        message = `Appointment with ${after.clientName} was marked as completed.`;
      } else if (after.status === "cancelled") {
        message = `Appointment with ${after.clientName} was cancelled.`;
      }

      await db.collection("notifications").add({
        userId: barberId,
        type: "status",
        title: "Appointment Update",
        body: message,
        meta: { appointmentId },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`📢 Status change notification sent to ${barberId}`);
    }
  });
