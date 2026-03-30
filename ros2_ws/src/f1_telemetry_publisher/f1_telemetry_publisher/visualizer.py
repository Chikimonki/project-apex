#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from f1_telemetry_msgs.msg import F1Telemetry
from visualization_msgs.msg import Marker, MarkerArray
import math

class F1Visualizer(Node):
    def __init__(self):
        super().__init__('f1_visualizer')
        
        self.subscription = self.create_subscription(
            F1Telemetry,
            'f1/telemetry',
            self.telemetry_callback,
            10
        )
        
        self.marker_pub = self.create_publisher(
            MarkerArray,
            'f1/visualization/markers',
            10
        )
        
        self.msg_count = 0
        
        self.get_logger().info('🎨 F1 Visualizer started')
        self.get_logger().info('   Subscribed to: /f1/telemetry')
        self.get_logger().info('   Publishing to: /f1/visualization/markers')
        
    def telemetry_callback(self, msg):
        self.msg_count += 1
        
        if self.msg_count % 10 == 0:
            self.get_logger().info(
                f'📊 Received {self.msg_count} msgs | '
                f'Speed: {msg.speed_kph:.1f} kph | Creating markers...'
            )
        
        markers = MarkerArray()
        now = self.get_clock().now().to_msg()
        
        # SPEED BAR (RED) - ID 0
        speed_marker = Marker()
        speed_marker.header.frame_id = "f1_car"
        speed_marker.header.stamp = now
        speed_marker.ns = "telemetry"
        speed_marker.id = 0  # Unique ID
        speed_marker.type = Marker.CUBE
        speed_marker.action = Marker.ADD
        speed_marker.pose.position.x = 0.0
        speed_marker.pose.position.y = 0.0
        speed_value = min(msg.speed_kph / 300.0, 1.0)  # Normalize
        speed_marker.pose.position.z = max(speed_value, 0.1) / 2.0
        speed_marker.pose.orientation.w = 1.0
        speed_marker.scale.x = 0.5
        speed_marker.scale.y = 0.5
        speed_marker.scale.z = max(speed_value, 0.1)
        speed_marker.color.r = 1.0
        speed_marker.color.g = 0.0
        speed_marker.color.b = 0.0
        speed_marker.color.a = 0.9
        speed_marker.lifetime.sec = 1
        markers.markers.append(speed_marker)
        
        # RPM BAR (GREEN) - ID 1
        rpm_marker = Marker()
        rpm_marker.header.frame_id = "f1_car"
        rpm_marker.header.stamp = now
        rpm_marker.ns = "telemetry"
        rpm_marker.id = 1  # Unique ID
        rpm_marker.type = Marker.CUBE
        rpm_marker.action = Marker.ADD
        rpm_marker.pose.position.x = 1.5
        rpm_marker.pose.position.y = 0.0
        rpm_value = min(msg.rpm / 15000.0, 1.0)
        rpm_marker.pose.position.z = max(rpm_value, 0.1) / 2.0
        rpm_marker.pose.orientation.w = 1.0
        rpm_marker.scale.x = 0.5
        rpm_marker.scale.y = 0.5
        rpm_marker.scale.z = max(rpm_value, 0.1)
        rpm_marker.color.r = 0.0
        rpm_marker.color.g = 1.0
        rpm_marker.color.b = 0.0
        rpm_marker.color.a = 0.9
        rpm_marker.lifetime.sec = 1
        markers.markers.append(rpm_marker)
        
        # THROTTLE BAR (BLUE) - ID 2
        throttle_marker = Marker()
        throttle_marker.header.frame_id = "f1_car"
        throttle_marker.header.stamp = now
        throttle_marker.ns = "telemetry"
        throttle_marker.id = 2  # Unique ID
        throttle_marker.type = Marker.CUBE
        throttle_marker.action = Marker.ADD
        throttle_marker.pose.position.x = 3.0
        throttle_marker.pose.position.y = 0.0
        throttle_value = msg.throttle_pct / 100.0
        throttle_marker.pose.position.z = max(throttle_value, 0.1) / 2.0
        throttle_marker.pose.orientation.w = 1.0
        throttle_marker.scale.x = 0.5
        throttle_marker.scale.y = 0.5
        throttle_marker.scale.z = max(throttle_value, 0.1)
        throttle_marker.color.r = 0.0
        throttle_marker.color.g = 0.0
        throttle_marker.color.b = 1.0
        throttle_marker.color.a = 0.9
        throttle_marker.lifetime.sec = 1
        markers.markers.append(throttle_marker)
        
        # LABEL TEXT - ID 3
        label_marker = Marker()
        label_marker.header.frame_id = "f1_car"
        label_marker.header.stamp = now
        label_marker.ns = "labels"
        label_marker.id = 3  # Unique ID
        label_marker.type = Marker.TEXT_VIEW_FACING
        label_marker.action = Marker.ADD
        label_marker.pose.position.x = 1.5
        label_marker.pose.position.y = 0.0
        label_marker.pose.position.z = 1.5
        label_marker.pose.orientation.w = 1.0
        label_marker.scale.z = 0.3
        label_marker.color.r = 1.0
        label_marker.color.g = 1.0
        label_marker.color.b = 1.0
        label_marker.color.a = 1.0
        label_marker.text = f"Speed: {msg.speed_kph:.0f} kph"
        label_marker.lifetime.sec = 1
        markers.markers.append(label_marker)
        
        self.marker_pub.publish(markers)
        
        if self.msg_count % 10 == 0:
            self.get_logger().info(f'   Published {len(markers.markers)} markers')

def main(args=None):
    rclpy.init(args=args)
    node = F1Visualizer()
    
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        node.get_logger().info('Shutting down...')
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
