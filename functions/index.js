const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const axios = require("axios"); // For triggering WhatsApp Cloud API HTTP posts
const nodemailer = require("nodemailer"); // For handling SMTP email dispatching

admin.initializeApp();

// ⏰ RUNS AUTOMATICALLY EVERY SINGLE DAY AT 8:00 AM SYSTEM TIME
exports.dailyChallengeAlertScheduler = onSchedule("every day 08:00", async (event) => {
  const db = admin.firestore();
  const now = new Date();
  
  // Calculate our precise target date threshold (Exactly 48 Hours out from today)
  const targetDate = new Date();
  targetDate.setDate(now.getDate() + 2);
  const targetDateString = targetDate.toISOString().split('T')[0]; // Format clean matching string: "YYYY-MM-DD"

  try {
    // 1. Scan your master tracking collection for data matches
    const recordsSnapshot = await db.collection("tracked_actions").get();
    
    if (recordsSnapshot.empty) {
      console.log("📝 Automation Log: No entries found inside tracked_actions collection.");
      return;
    }

    for (let doc of recordsSnapshot.docs) {
      const record = doc.data();
      if (!record.followUpDate) continue;

      // Extract the record's follow-up date string fragment (handles Timestamp objects or ISO Strings safely)
      let recordDateString = "";
      if (typeof record.followUpDate === 'string') {
        recordDateString = record.followUpDate.split('T')[0];
      } else if (record.followUpDate.toDate) {
        recordDateString = record.followUpDate.toDate().toISOString().split('T')[0];
      }

      // 🎯 IF THE RECORD IS DUE IN EXACTLY 2 DAYS:
      if (recordDateString === targetDateString) {
        // 2. Fetch the logged user's matching metadata profile links
        const userDoc = await db.collection("users").doc(record.userId).get();
        if (!userDoc.exists) {
          console.log(`⚠️ User metadata profile not found for ID: ${record.userId}`);
          continue;
        }
        
        const userData = userDoc.data();
        const userPhone = userData.phoneNumber; // Already strictly formatted with + country prefix via login validation!
        const userEmail = userData.email;

        const alertMessage = `⏰ 1000 Challenge Reminder:\nYour follow-up action for '${record.roleOpportunity}' is due in 2 days on ${targetDateString}.\n\nFollow-up Target Note: ${record.followUp}`;

        console.log(`🚀 Triggering automated relays for user: ${userEmail} regarding record ID: ${doc.id}`);

        // =========================================================================
        // 💬 TRANSMIT AUTOMATED WHATSAPP VIA META CLOUD API
        // =========================================================================
        try {
          await axios.post(
            `https://graph.facebook.com/v23.0/YOUR_WHATSAPP_PHONE_NUMBER_ID/messages`,
            {
              messaging_product: "whatsapp",
              to: userPhone,
              type: "text",
              text: { body: alertMessage }
            },
            {
              headers: { 
                "Authorization": `Bearer YOUR_META_PERMANENT_ACCESS_TOKEN`,
                "Content-Type": "application/json"
              }
            }
          );
          console.log(`✅ WhatsApp alert successfully delivered to ${userPhone}`);
        } catch (waError) {
          console.error(`❌ Meta WhatsApp Cloud API Delivery Failed: ${waError.response?.data ? JSON.stringify(waError.response.data) : waError.message}`);
        }

        // =========================================================================
        // ✉️ TRANSMIT AUTOMATED SYSTEM EMAIL VIA SMTP
        // =========================================================================
        try {
          let transporter = nodemailer.createTransport({
            service: 'gmail', // Standard configuration for Gmail application password routing
            auth: { 
              user: 'your-email@gmail.com', // Replace with your sender Gmail address
              pass: 'your-app-password'     // Replace with your secure Google Account App Password
            }
          });

          await transporter.sendMail({
            from: '"1000 Challenge Platform" <your-email@gmail.com>',
            to: userEmail,
            subject: `⏰ Action Required: Follow-up Reminder for ${record.roleOpportunity}`,
            text: alertMessage
          });
          console.log(`✅ SMTP Verification Email successfully delivered to ${userEmail}`);
        } catch (emailError) {
          console.error(`❌ Mail Dispatch Loop Failed: ${emailError.message}`);
        }
      }
    }
  } catch (globalError) {
    console.error(`❌ Scheduler Execution Engine crashed: ${globalError.message}`);
  }
});