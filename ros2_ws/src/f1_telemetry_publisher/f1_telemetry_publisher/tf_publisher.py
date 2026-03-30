#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import TransformStamped
from tf2_ros import StaticTransformBroadcaster

class F1TFPublisher(Node):
    def __init__(self):
        super().__init__('f1_tf_publisher')
        
        self.tf_broadcaster = StaticTransformBroadcaster(self)
        
        # Publish f1_car frame relative to world
        transform = TransformStamped()
        transform.header.stamp = self.get_clock().now().to_msg()
        transform.header.frame_id = 'world'
        transform.child_frame_id = 'f1_car'
        
        # Identity transform (car at origin)
        transform.transform.translation.x = 0.0
        transform.transform.translation.y = 0.0
        transform.transform.translation.z = 0.0
        transform.transform.rotation.w = 1.0
        
        self.tf_broadcaster.sendTransform(transform)
        
        self.get_logger().info('📍 Published TF: world -> f1_car')

def main(args=None):
    rclpy.init(args=args)
    node = F1TFPublisher()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
