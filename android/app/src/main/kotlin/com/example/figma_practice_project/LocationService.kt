package com.example.figma_practice_project
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.app.*
import android.content.Intent
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.auth.FirebaseAuth
import java.sql.Timestamp
import java.time.format.DateTimeFormatter

@Suppress("UNREACHABLE_CODE")
class LocationService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val CHANNEL_ID = "my_foreground"
    private val dbRef = FirebaseDatabase.getInstance().reference

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        startForegroundNotification()
        startLocationUpdates()
    }

    private fun startForegroundNotification() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Background Location",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Tracking in background")
            .setContentText("Your location is being updated.")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
    }

    private fun fetchUserData(uid: String, onComplete: (Map<String, Any>?) -> Unit) {
        val userRef = FirebaseDatabase.getInstance().getReference("users").child(uid)
        userRef.get().addOnSuccessListener { snapshot ->
            val userData = snapshot.value as? Map<String, Any>
            onComplete(userData)
        }.addOnFailureListener {
            onComplete(null)
        }
    }

    private fun startLocationUpdates() {
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10000).build()

        fusedLocationClient.requestLocationUpdates(request, object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val location = result.lastLocation ?: return

                val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                val currentDate = sdf.format(Date(System.currentTimeMillis()))

                val user = FirebaseAuth.getInstance().currentUser
                val uid = user?.uid ?: "anonymous"

                // Fetch user info from Realtime Database
                fetchUserData(uid) { userData ->
                    val tehsilName = userData?.get("tehsil_name") as? String ?: "Unknown"
                    val tehsilId  = userData?.get("tehsil_id") as? String ?: "Unknown"
                    val ucName = userData?.get("union_council_name") as? String ?: "Unknown"
                    val ucId = userData?.get("union_council_id") as? String ?: "Unknown"
                    val userName = userData?.get("name") as? String ?: "Unknown"

                    val data = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "timestamp" to currentDate,
                        "name" to userName,
                        "tehsil_name" to tehsilName,
                        "tehsil_id" to tehsilId,
                        "union_council_name" to ucName,
                        "union_council_id" to ucId
                    )

                    // Save both current and history
                    dbRef.child("locations").child(uid).child("logs").push().setValue(data)
                    dbRef.child("current_locations").child(uid).setValue(data)

                    Log.d(
                        "LocationService",
                        "✅ Sent: ${location.latitude}, ${location.longitude} | $userName, $tehsilName"
                    )
                }
            }
        }, Looper.getMainLooper())
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
