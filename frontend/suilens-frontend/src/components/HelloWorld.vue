<template>
  <v-container class="py-8" max-width="800">
    <v-card>
      <v-card-title class="d-flex align-center">
        Live Order Notifications
        <v-spacer></v-spacer>
        <v-chip
          :color="connected ? 'success' : 'error'"
          size="small"
          variant="flat"
        >
          <v-icon start size="x-small">{{ connected ? 'mdi-wifi' : 'mdi-wifi-off' }}</v-icon>
          {{ connected ? 'Connected' : 'Disconnected' }}
        </v-chip>
      </v-card-title>
      <v-divider></v-divider>

      <v-card-text class="py-6" style="min-height: 500px">
        <div
          v-if="notifications.length === 0"
          class="text-center text-grey py-8"
        >
          <p class="text-sm">No notifications yet</p>
        </div>

        <div v-else>
          <div
            v-for="(notification, index) in notifications"
            :key="index"
            class="mb-4 pb-4"
            :style="
              index < notifications.length - 1
                ? 'border-bottom: 1px solid #eee;'
                : ''
            "
          >
            <p class="text-sm ma-0">
              Order placed for <strong>{{ notification.data.lensName }}</strong> by
              <strong>{{ notification.data.customerName }}</strong>
              ({{ notification.data.customerEmail }})
            </p>
            <p class="text-xs text-grey-darken-1 mt-1">
              Order ID: {{ notification.data.orderId }}
            </p>
            <p class="text-xs text-grey-darken-1 mt-1">
              {{ formatTime(notification.timestamp) }}
            </p>
          </div>
        </div>
      </v-card-text>

      <v-divider v-if="notifications.length > 0"></v-divider>
      <v-card-actions v-if="notifications.length > 0">
        <v-spacer></v-spacer>
        <v-btn size="small" variant="text" @click="clearNotifications">
          Clear
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-container>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";

const WS_URL =
  import.meta.env.VITE_NOTIFICATION_WS || "ws://localhost:3003/ws";

const notifications = ref([]);
const connected = ref(false);
let ws = null;
let reconnectTimer = null;

function connect() {
  ws = new WebSocket(WS_URL);

  ws.onopen = () => {
    connected.value = true;
    console.log("WebSocket connected to notification service");
  };

  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      notifications.value.unshift(data);
    } catch (e) {
      console.error("Failed to parse WebSocket message:", e);
    }
  };

  ws.onclose = () => {
    connected.value = false;
    console.log("WebSocket disconnected, reconnecting in 3s...");
    reconnectTimer = setTimeout(connect, 3000);
  };

  ws.onerror = (err) => {
    console.error("WebSocket error:", err);
    ws.close();
  };
}

function formatTime(timestamp) {
  const date = new Date(timestamp);
  return date.toLocaleTimeString("en-US", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function clearNotifications() {
  notifications.value = [];
}

onMounted(() => {
  connect();
});

onUnmounted(() => {
  if (reconnectTimer) clearTimeout(reconnectTimer);
  if (ws) ws.close();
});
</script>
