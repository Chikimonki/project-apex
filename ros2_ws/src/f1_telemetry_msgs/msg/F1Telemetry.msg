# F1 Telemetry Message
std_msgs/Header header

# Vehicle dynamics
float32 speed_kph
float32 rpm
float32 throttle_pct
float32 brake_pct
int8 gear
float32 steering_angle

# CAN metadata
uint32 can_id
