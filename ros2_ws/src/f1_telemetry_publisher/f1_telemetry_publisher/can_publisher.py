#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from std_msgs.msg import Header
import json
import sys
import select

try:
    from f1_telemetry_msgs.msg import F1Telemetry
    HAS_CUSTOM_MSG = True
except ImportError:
    HAS_CUSTOM_MSG = False

class CANTelemetryPublisher(Node):
    def __init__(self):
        super().__init__('f1_telemetry_publisher')
        
        if HAS_CUSTOM_MSG:
            self.publisher_ = self.create_publisher(F1Telemetry, 'f1/telemetry', 10)
        
        self.msg_count = 0
        self.get_logger().info('🏎️  F1 Telemetry Publisher started')
        self.get_logger().info('   Reading JSON from stdin...')
        
        self.timer = self.create_timer(0.01, self.check_stdin)
        
    def check_stdin(self):
        try:
            if select.select([sys.stdin], [], [], 0)[0]:
                line = sys.stdin.readline()
                
                if not line:
                    self.get_logger().info('📭 EOF reached, shutting down...')
                    rclpy.shutdown()
                    return
                
                line = line.strip()
                if not line or not line.startswith('{'):
                    return
                
                try:
                    data = json.loads(line)
                    self.publish_telemetry(data)
                except json.JSONDecodeError as e:
                    self.get_logger().warn(f'Invalid JSON: {e}')
                    
        except Exception as e:
            self.get_logger().error(f'Error: {e}')
    
    def publish_telemetry(self, data):
        if not HAS_CUSTOM_MSG:
            return
            
        msg = F1Telemetry()
        
        # Set header if it exists in the message
        if hasattr(msg, 'header'):
            msg.header.stamp = self.get_clock().now().to_msg()
            msg.header.frame_id = 'f1_car'
        
        # Set fields
        msg.speed_kph = float(data.get('speed', 0))
        msg.rpm = float(data.get('rpm', 0))
        msg.throttle_pct = float(data.get('throttle', 0))
        msg.brake_pct = float(data.get('brake', 0))
        msg.gear = int(data.get('gear', 0))
        msg.steering_angle = float(data.get('steering_angle', 0))
        msg.can_id = int(data.get('can_id', 0))
        
        self.publisher_.publish(msg)
        self.msg_count += 1
        
        if self.msg_count % 5 == 0:
            self.get_logger().info(
                f'📤 Published {self.msg_count} msgs | Speed: {msg.speed_kph:.1f} kph'
            )

def main(args=None):
    rclpy.init(args=args)
    node = CANTelemetryPublisher()
    
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()

if __name__ == '__main__':
    main()
