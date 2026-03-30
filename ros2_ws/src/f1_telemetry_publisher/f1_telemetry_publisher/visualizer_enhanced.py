#!/usr/bin/env python3
"""
Enhanced F1 Visualizer with crisp text, car model, 6-car support
"""
import rclpy
from rclpy.node import Node
from f1_telemetry_msgs.msg import F1Telemetry
from visualization_msgs.msg import Marker, MarkerArray
from geometry_msgs.msg import Point
import math

class F1VisualizerEnhanced(Node):
    def __init__(self):
        super().__init__('f1_visualizer_enhanced')
        
        self.subscription = self.create_subscription(
            F1Telemetry, 'f1/telemetry', self.telemetry_callback, 10
        )
        
        self.marker_pub = self.create_publisher(MarkerArray, 'f1/visualization/markers', 10)
        self.msg_count = 0
        
        # Car colors for multi-car support
        self.car_colors = {
            'ferrari_488': (0.8, 0.1, 0.1),      # Red
            'mclaren_p1': (1.0, 0.5, 0.0),       # Orange
            'porsche_911': (0.0, 0.4, 0.8),      # Blue
            'porsche_cayman': (0.9, 0.9, 0.0),   # Yellow
            'ferrari_f12': (0.8, 0.0, 0.2),      # Dark Red
            'aston_martin': (0.0, 0.5, 0.3),     # British Racing Green
        }
        
        self.get_logger().info('🏎️  Enhanced F1 Visualizer started')
        
    def telemetry_callback(self, msg):
        self.msg_count += 1
        markers = MarkerArray()
        now = self.get_clock().now().to_msg()
        marker_id = 0
        
        # Delete all previous markers for clean update
        delete_marker = Marker()
        delete_marker.header.frame_id = "f1_car"
        delete_marker.action = Marker.DELETEALL
        markers.markers.append(delete_marker)
        marker_id += 1
        
        # === CAR CHASSIS (Sleek F1 shape) ===
        chassis = Marker()
        chassis.header.frame_id = "f1_car"
        chassis.header.stamp = now
        chassis.ns = "car"
        chassis.id = marker_id; marker_id += 1
        chassis.type = Marker.CUBE
        chassis.action = Marker.ADD
        chassis.pose.position.x = 0.0
        chassis.pose.position.y = 0.0
        chassis.pose.position.z = 0.25
        chassis.pose.orientation.w = 1.0
        chassis.scale.x = 2.5  # Length
        chassis.scale.y = 0.8  # Width
        chassis.scale.z = 0.3  # Height
        chassis.color.r = 0.8
        chassis.color.g = 0.1
        chassis.color.b = 0.1
        chassis.color.a = 1.0
        markers.markers.append(chassis)
        
        # === COCKPIT ===
        cockpit = Marker()
        cockpit.header.frame_id = "f1_car"
        cockpit.header.stamp = now
        cockpit.ns = "car"
        cockpit.id = marker_id; marker_id += 1
        cockpit.type = Marker.CUBE
        cockpit.action = Marker.ADD
        cockpit.pose.position.x = -0.3
        cockpit.pose.position.y = 0.0
        cockpit.pose.position.z = 0.5
        cockpit.pose.orientation.w = 1.0
        cockpit.scale.x = 0.8
        cockpit.scale.y = 0.5
        cockpit.scale.z = 0.3
        cockpit.color.r = 0.2
        cockpit.color.g = 0.2
        cockpit.color.b = 0.2
        cockpit.color.a = 1.0
        markers.markers.append(cockpit)
        
        # === 4 WHEELS ===
        wheel_positions = [
            (1.0, 0.5),   # Front left
            (1.0, -0.5),  # Front right
            (-0.8, 0.5),  # Rear left
            (-0.8, -0.5)  # Rear right
        ]
        
        for i, (x, y) in enumerate(wheel_positions):
            wheel = Marker()
            wheel.header.frame_id = "f1_car"
            wheel.header.stamp = now
            wheel.ns = "wheels"
            wheel.id = marker_id; marker_id += 1
            wheel.type = Marker.CYLINDER
            wheel.action = Marker.ADD
            wheel.pose.position.x = x
            wheel.pose.position.y = y
            wheel.pose.position.z = 0.15
            wheel.pose.orientation.x = 0.707
            wheel.pose.orientation.w = 0.707
            wheel.scale.x = 0.35
            wheel.scale.y = 0.35
            wheel.scale.z = 0.2
            wheel.color.r = 0.1
            wheel.color.g = 0.1
            wheel.color.b = 0.1
            wheel.color.a = 1.0
            markers.markers.append(wheel)
            
            # Brake glow when braking
            if msg.brake_pct > 5:
                brake_glow = Marker()
                brake_glow.header.frame_id = "f1_car"
                brake_glow.header.stamp = now
                brake_glow.ns = "brakes"
                brake_glow.id = marker_id; marker_id += 1
                brake_glow.type = Marker.SPHERE
                brake_glow.action = Marker.ADD
                brake_glow.pose.position.x = x
                brake_glow.pose.position.y = y
                brake_glow.pose.position.z = 0.15
                brake_glow.pose.orientation.w = 1.0
                intensity = min(msg.brake_pct / 100.0, 1.0)
                brake_glow.scale.x = 0.3 + 0.2 * intensity
                brake_glow.scale.y = 0.3 + 0.2 * intensity
                brake_glow.scale.z = 0.3 + 0.2 * intensity
                brake_glow.color.r = 1.0
                brake_glow.color.g = 0.3 * (1.0 - intensity)
                brake_glow.color.b = 0.0
                brake_glow.color.a = 0.7 * intensity
                markers.markers.append(brake_glow)
        
        # === TELEMETRY BARS (Clean layout to the right) ===
        bar_x = 4.0
        bar_spacing = 1.2
        bar_width = 0.4
        max_height = 2.5
        
        # Speed bar (RED)
        speed_pct = min(msg.speed_kph / 350.0, 1.0)
        markers.markers.append(self.create_bar(
            marker_id, "speed", bar_x, 0.0, speed_pct, max_height, bar_width,
            (1.0, 0.2, 0.2), now
        ))
        marker_id += 1
        
        # RPM bar (GREEN)
        rpm_pct = min(msg.rpm / 10000.0, 1.0)
        markers.markers.append(self.create_bar(
            marker_id, "rpm", bar_x + bar_spacing, 0.0, rpm_pct, max_height, bar_width,
            (0.2, 1.0, 0.2), now
        ))
        marker_id += 1
        
        # Throttle bar (BLUE)
        throttle_pct = msg.throttle_pct / 100.0
        markers.markers.append(self.create_bar(
            marker_id, "throttle", bar_x + bar_spacing * 2, 0.0, throttle_pct, max_height, bar_width,
            (0.2, 0.5, 1.0), now
        ))
        marker_id += 1
        
        # Brake bar (ORANGE)
        brake_pct = msg.brake_pct / 100.0
        markers.markers.append(self.create_bar(
            marker_id, "brake", bar_x + bar_spacing * 3, 0.0, brake_pct, max_height, bar_width,
            (1.0, 0.5, 0.0), now
        ))
        marker_id += 1
        
        # === BAR LABELS (Below bars) ===
        labels = [
            ("SPD", bar_x),
            ("RPM", bar_x + bar_spacing),
            ("THR", bar_x + bar_spacing * 2),
            ("BRK", bar_x + bar_spacing * 3),
        ]
        
        for label_text, x in labels:
            label = Marker()
            label.header.frame_id = "f1_car"
            label.header.stamp = now
            label.ns = "bar_labels"
            label.id = marker_id; marker_id += 1
            label.type = Marker.TEXT_VIEW_FACING
            label.action = Marker.ADD
            label.pose.position.x = x
            label.pose.position.y = 0.0
            label.pose.position.z = -0.3
            label.pose.orientation.w = 1.0
            label.scale.z = 0.25
            label.color.r = 0.8
            label.color.g = 0.8
            label.color.b = 0.8
            label.color.a = 1.0
            label.text = label_text
            markers.markers.append(label)
        
        # === MAIN SPEED DISPLAY (Large, crisp) ===
        speed_display = Marker()
        speed_display.header.frame_id = "f1_car"
        speed_display.header.stamp = now
        speed_display.ns = "speed_display"
        speed_display.id = marker_id; marker_id += 1
        speed_display.type = Marker.TEXT_VIEW_FACING
        speed_display.action = Marker.ADD
        speed_display.pose.position.x = 0.0
        speed_display.pose.position.y = 0.0
        speed_display.pose.position.z = 2.5
        speed_display.pose.orientation.w = 1.0
        speed_display.scale.z = 0.6  # Larger text
        speed_display.color.r = 0.0
        speed_display.color.g = 1.0
        speed_display.color.b = 1.0
        speed_display.color.a = 1.0
        speed_display.text = f"{int(msg.speed_kph):3d} km/h"
        markers.markers.append(speed_display)
        
        # === MPH DISPLAY (Secondary, smaller) ===
        mph_display = Marker()
        mph_display.header.frame_id = "f1_car"
        mph_display.header.stamp = now
        mph_display.ns = "mph_display"
        mph_display.id = marker_id; marker_id += 1
        mph_display.type = Marker.TEXT_VIEW_FACING
        mph_display.action = Marker.ADD
        mph_display.pose.position.x = 0.0
        mph_display.pose.position.y = 0.0
        mph_display.pose.position.z = 2.1
        mph_display.pose.orientation.w = 1.0
        mph_display.scale.z = 0.35
        mph_display.color.r = 0.7
        mph_display.color.g = 0.7
        mph_display.color.b = 0.7
        mph_display.color.a = 0.9
        mph = msg.speed_kph * 0.621371
        mph_display.text = f"({int(mph):3d} mph)"
        markers.markers.append(mph_display)
        
        # === GEAR DISPLAY (Big and bold) ===
        gear_display = Marker()
        gear_display.header.frame_id = "f1_car"
        gear_display.header.stamp = now
        gear_display.ns = "gear"
        gear_display.id = marker_id; marker_id += 1
        gear_display.type = Marker.TEXT_VIEW_FACING
        gear_display.action = Marker.ADD
        gear_display.pose.position.x = 0.0
        gear_display.pose.position.y = 0.0
        gear_display.pose.position.z = 1.5
        gear_display.pose.orientation.w = 1.0
        gear_display.scale.z = 0.8
        gear_display.color.r = 1.0
        gear_display.color.g = 0.9
        gear_display.color.b = 0.0
        gear_display.color.a = 1.0
        gear_text = str(msg.gear) if msg.gear > 0 else "N"
        gear_display.text = gear_text
        markers.markers.append(gear_display)
        
        # === RPM DISPLAY ===
        rpm_display = Marker()
        rpm_display.header.frame_id = "f1_car"
        rpm_display.header.stamp = now
        rpm_display.ns = "rpm_display"
        rpm_display.id = marker_id; marker_id += 1
        rpm_display.type = Marker.TEXT_VIEW_FACING
        rpm_display.action = Marker.ADD
        rpm_display.pose.position.x = 0.0
        rpm_display.pose.position.y = 0.0
        rpm_display.pose.position.z = 1.0
        rpm_display.pose.orientation.w = 1.0
        rpm_display.scale.z = 0.3
        rpm_display.color.r = 0.3
        rpm_display.color.g = 1.0
        rpm_display.color.b = 0.3
        rpm_display.color.a = 1.0
        rpm_display.text = f"{int(msg.rpm):5d} RPM"
        markers.markers.append(rpm_display)
        
        # === STEERING INDICATOR (Arrow) ===
        if abs(msg.steering_angle) > 1:
            steering_arrow = Marker()
            steering_arrow.header.frame_id = "f1_car"
            steering_arrow.header.stamp = now
            steering_arrow.ns = "steering"
            steering_arrow.id = marker_id; marker_id += 1
            steering_arrow.type = Marker.ARROW
            steering_arrow.action = Marker.ADD
            
            start = Point()
            start.x = 1.5
            start.y = 0.0
            start.z = 0.5
            
            angle_rad = math.radians(msg.steering_angle)
            arrow_length = abs(msg.steering_angle) / 45.0 * 1.0
            
            end = Point()
            end.x = 1.5 + math.cos(angle_rad + math.pi/2) * arrow_length
            end.y = math.sin(angle_rad + math.pi/2) * arrow_length
            end.z = 0.5
            
            steering_arrow.points = [start, end]
            steering_arrow.scale.x = 0.08
            steering_arrow.scale.y = 0.15
            steering_arrow.color.r = 1.0
            steering_arrow.color.g = 1.0
            steering_arrow.color.b = 0.0
            steering_arrow.color.a = 0.9
            markers.markers.append(steering_arrow)
        
        # === G-FORCE INDICATOR ===
        g_longitudinal = (msg.throttle_pct - msg.brake_pct) / 100.0 * 1.5
        if abs(g_longitudinal) > 0.1:
            g_arrow = Marker()
            g_arrow.header.frame_id = "f1_car"
            g_arrow.header.stamp = now
            g_arrow.ns = "g_force"
            g_arrow.id = marker_id; marker_id += 1
            g_arrow.type = Marker.ARROW
            g_arrow.action = Marker.ADD
            
            start = Point()
            start.x = 0.0
            start.y = 0.0
            start.z = 0.6
            
            end = Point()
            end.x = g_longitudinal
            end.y = 0.0
            end.z = 0.6
            
            g_arrow.points = [start, end]
            g_arrow.scale.x = 0.1
            g_arrow.scale.y = 0.2
            if g_longitudinal > 0:
                g_arrow.color.r = 0.0
                g_arrow.color.g = 1.0
                g_arrow.color.b = 0.0
            else:
                g_arrow.color.r = 1.0
                g_arrow.color.g = 0.0
                g_arrow.color.b = 0.0
            g_arrow.color.a = 0.8
            markers.markers.append(g_arrow)
        
        self.marker_pub.publish(markers)
        
        if self.msg_count % 50 == 0:
            self.get_logger().info(
                f'📊 {self.msg_count} msgs | {int(msg.speed_kph)} km/h | G{msg.gear}'
            )
    
    def create_bar(self, id, ns, x, y, value, max_height, width, color, stamp):
        marker = Marker()
        marker.header.frame_id = "f1_car"
        marker.header.stamp = stamp
        marker.ns = ns
        marker.id = id
        marker.type = Marker.CUBE
        marker.action = Marker.ADD
        
        height = max(value * max_height, 0.05)
        marker.pose.position.x = x
        marker.pose.position.y = y
        marker.pose.position.z = height / 2.0
        marker.pose.orientation.w = 1.0
        
        marker.scale.x = width
        marker.scale.y = width
        marker.scale.z = height
        
        marker.color.r = color[0]
        marker.color.g = color[1]
        marker.color.b = color[2]
        marker.color.a = 0.9
        
        return marker

def main(args=None):
    rclpy.init(args=args)
    node = F1VisualizerEnhanced()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
