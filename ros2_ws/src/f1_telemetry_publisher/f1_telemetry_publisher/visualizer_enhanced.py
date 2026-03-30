#!/usr/bin/env python3
"""
Enhanced F1 Visualizer - Bigger car, right-aligned layout
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
        
        self.get_logger().info('🏎️ Enhanced F1 Visualizer started')
        
    def telemetry_callback(self, msg):
        self.msg_count += 1
        markers = MarkerArray()
        now = self.get_clock().now().to_msg()
        marker_id = 0
        
        # Delete all previous markers
        delete_marker = Marker()
        delete_marker.header.frame_id = "f1_car"
        delete_marker.action = Marker.DELETEALL
        markers.markers.append(delete_marker)
        marker_id += 1
        
        # === CAR POSITION (Left side of view) ===
        car_x = -3.0
        
        # === MAIN CHASSIS (Bigger) ===
        chassis = Marker()
        chassis.header.frame_id = "f1_car"
        chassis.header.stamp = now
        chassis.ns = "car"
        chassis.id = marker_id; marker_id += 1
        chassis.type = Marker.CUBE
        chassis.action = Marker.ADD
        chassis.pose.position.x = car_x
        chassis.pose.position.y = 0.0
        chassis.pose.position.z = 0.4
        chassis.pose.orientation.w = 1.0
        chassis.scale.x = 4.0  # Length (bigger!)
        chassis.scale.y = 1.5  # Width (bigger!)
        chassis.scale.z = 0.5  # Height
        chassis.color.r = 0.9
        chassis.color.g = 0.1
        chassis.color.b = 0.1
        chassis.color.a = 1.0
        markers.markers.append(chassis)
        
        # === NOSE ===
        nose = Marker()
        nose.header.frame_id = "f1_car"
        nose.header.stamp = now
        nose.ns = "car"
        nose.id = marker_id; marker_id += 1
        nose.type = Marker.CUBE
        nose.action = Marker.ADD
        nose.pose.position.x = car_x + 2.5
        nose.pose.position.y = 0.0
        nose.pose.position.z = 0.3
        nose.pose.orientation.w = 1.0
        nose.scale.x = 1.5
        nose.scale.y = 0.8
        nose.scale.z = 0.3
        nose.color.r = 0.8
        nose.color.g = 0.1
        nose.color.b = 0.1
        nose.color.a = 1.0
        markers.markers.append(nose)
        
        # === COCKPIT ===
        cockpit = Marker()
        cockpit.header.frame_id = "f1_car"
        cockpit.header.stamp = now
        cockpit.ns = "car"
        cockpit.id = marker_id; marker_id += 1
        cockpit.type = Marker.CUBE
        cockpit.action = Marker.ADD
        cockpit.pose.position.x = car_x - 0.5
        cockpit.pose.position.y = 0.0
        cockpit.pose.position.z = 0.8
        cockpit.pose.orientation.w = 1.0
        cockpit.scale.x = 1.2
        cockpit.scale.y = 0.7
        cockpit.scale.z = 0.5
        cockpit.color.r = 0.15
        cockpit.color.g = 0.15
        cockpit.color.b = 0.15
        cockpit.color.a = 1.0
        markers.markers.append(cockpit)
        
        # === REAR WING ===
        wing = Marker()
        wing.header.frame_id = "f1_car"
        wing.header.stamp = now
        wing.ns = "car"
        wing.id = marker_id; marker_id += 1
        wing.type = Marker.CUBE
        wing.action = Marker.ADD
        wing.pose.position.x = car_x - 2.3
        wing.pose.position.y = 0.0
        wing.pose.position.z = 1.0
        wing.pose.orientation.w = 1.0
        wing.scale.x = 0.15
        wing.scale.y = 2.0
        wing.scale.z = 0.4
        wing.color.r = 0.2
        wing.color.g = 0.2
        wing.color.b = 0.2
        wing.color.a = 1.0
        markers.markers.append(wing)
        
        # === 4 WHEELS (Bigger) ===
        wheel_positions = [
            (car_x + 1.5, 0.9),   # Front left
            (car_x + 1.5, -0.9),  # Front right
            (car_x - 1.5, 0.9),   # Rear left
            (car_x - 1.5, -0.9)   # Rear right
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
            wheel.pose.position.z = 0.25
            wheel.pose.orientation.x = 0.707
            wheel.pose.orientation.w = 0.707
            wheel.scale.x = 0.5  # Diameter (bigger!)
            wheel.scale.y = 0.5
            wheel.scale.z = 0.3  # Width
            wheel.color.r = 0.1
            wheel.color.g = 0.1
            wheel.color.b = 0.1
            wheel.color.a = 1.0
            markers.markers.append(wheel)
            
            # Brake glow
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
                brake_glow.pose.position.z = 0.25
                brake_glow.pose.orientation.w = 1.0
                intensity = min(msg.brake_pct / 100.0, 1.0)
                brake_glow.scale.x = 0.4 + 0.3 * intensity
                brake_glow.scale.y = 0.4 + 0.3 * intensity
                brake_glow.scale.z = 0.4 + 0.3 * intensity
                brake_glow.color.r = 1.0
                brake_glow.color.g = 0.2 * (1.0 - intensity)
                brake_glow.color.b = 0.0
                brake_glow.color.a = 0.8 * intensity
                markers.markers.append(brake_glow)
        
        # === TELEMETRY PANEL (Right side) ===
        panel_x = 4.0
        
        # Background panel
        panel_bg = Marker()
        panel_bg.header.frame_id = "f1_car"
        panel_bg.header.stamp = now
        panel_bg.ns = "panel"
        panel_bg.id = marker_id; marker_id += 1
        panel_bg.type = Marker.CUBE
        panel_bg.action = Marker.ADD
        panel_bg.pose.position.x = panel_x + 2.5
        panel_bg.pose.position.y = 0.0
        panel_bg.pose.position.z = 1.5
        panel_bg.pose.orientation.w = 1.0
        panel_bg.scale.x = 0.1
        panel_bg.scale.y = 6.0
        panel_bg.scale.z = 4.0
        panel_bg.color.r = 0.1
        panel_bg.color.g = 0.1
        panel_bg.color.b = 0.15
        panel_bg.color.a = 0.8
        markers.markers.append(panel_bg)
        
        # === TELEMETRY BARS ===
        bar_x = panel_x
        bar_spacing = 1.2
        bar_width = 0.5
        max_height = 3.0
        
        # Speed bar (RED)
        speed_pct = min(msg.speed_kph / 350.0, 1.0)
        markers.markers.append(self.create_bar(
            marker_id, "speed", bar_x, -1.8, speed_pct, max_height, bar_width,
            (1.0, 0.2, 0.2), now
        ))
        marker_id += 1
        
        # RPM bar (GREEN)
        rpm_pct = min(msg.rpm / 10000.0, 1.0)
        markers.markers.append(self.create_bar(
            marker_id, "rpm", bar_x, -0.6, rpm_pct, max_height, bar_width,
            (0.2, 1.0, 0.2), now
        ))
        marker_id += 1
        
        # Throttle bar (BLUE)
        throttle_pct = msg.throttle_pct / 100.0
        markers.markers.append(self.create_bar(
            marker_id, "throttle", bar_x, 0.6, throttle_pct, max_height, bar_width,
            (0.2, 0.5, 1.0), now
        ))
        marker_id += 1
        
        # Brake bar (ORANGE)
        brake_pct = msg.brake_pct / 100.0
        markers.markers.append(self.create_bar(
            marker_id, "brake", bar_x, 1.8, brake_pct, max_height, bar_width,
            (1.0, 0.5, 0.0), now
        ))
        marker_id += 1
        
        # === BAR LABELS ===
        labels = [
            ("SPD", -1.8),
            ("RPM", -0.6),
            ("THR", 0.6),
            ("BRK", 1.8),
        ]
        
        for label_text, y in labels:
            label = Marker()
            label.header.frame_id = "f1_car"
            label.header.stamp = now
            label.ns = "labels"
            label.id = marker_id; marker_id += 1
            label.type = Marker.TEXT_VIEW_FACING
            label.action = Marker.ADD
            label.pose.position.x = bar_x
            label.pose.position.y = y
            label.pose.position.z = -0.3
            label.pose.orientation.w = 1.0
            label.scale.z = 0.3
            label.color.r = 0.9
            label.color.g = 0.9
            label.color.b = 0.9
            label.color.a = 1.0
            label.text = label_text
            markers.markers.append(label)
        
        # === MAIN SPEED DISPLAY ===
        speed_display = Marker()
        speed_display.header.frame_id = "f1_car"
        speed_display.header.stamp = now
        speed_display.ns = "display"
        speed_display.id = marker_id; marker_id += 1
        speed_display.type = Marker.TEXT_VIEW_FACING
        speed_display.action = Marker.ADD
        speed_display.pose.position.x = car_x
        speed_display.pose.position.y = 0.0
        speed_display.pose.position.z = 2.5
        speed_display.pose.orientation.w = 1.0
        speed_display.scale.z = 0.8
        speed_display.color.r = 0.0
        speed_display.color.g = 1.0
        speed_display.color.b = 1.0
        speed_display.color.a = 1.0
        speed_display.text = f"{int(msg.speed_kph)} km/h"
        markers.markers.append(speed_display)
        
        # === MPH DISPLAY ===
        mph_display = Marker()
        mph_display.header.frame_id = "f1_car"
        mph_display.header.stamp = now
        mph_display.ns = "display"
        mph_display.id = marker_id; marker_id += 1
        mph_display.type = Marker.TEXT_VIEW_FACING
        mph_display.action = Marker.ADD
        mph_display.pose.position.x = car_x
        mph_display.pose.position.y = 0.0
        mph_display.pose.position.z = 2.0
        mph_display.pose.orientation.w = 1.0
        mph_display.scale.z = 0.4
        mph_display.color.r = 0.7
        mph_display.color.g = 0.7
        mph_display.color.b = 0.7
        mph_display.color.a = 1.0
        mph = msg.speed_kph * 0.621371
        mph_display.text = f"({int(mph)} mph)"
        markers.markers.append(mph_display)
        
        # === GEAR DISPLAY (Large) ===
        gear_display = Marker()
        gear_display.header.frame_id = "f1_car"
        gear_display.header.stamp = now
        gear_display.ns = "display"
        gear_display.id = marker_id; marker_id += 1
        gear_display.type = Marker.TEXT_VIEW_FACING
        gear_display.action = Marker.ADD
        gear_display.pose.position.x = car_x
        gear_display.pose.position.y = 0.0
        gear_display.pose.position.z = 1.4
        gear_display.pose.orientation.w = 1.0
        gear_display.scale.z = 1.0
        gear_display.color.r = 1.0
        gear_display.color.g = 0.9
        gear_display.color.b = 0.0
        gear_display.color.a = 1.0
        gear_text = str(msg.gear) if msg.gear > 0 else "N"
        gear_display.text = gear_text
        markers.markers.append(gear_display)
        
        # === G-FORCE ARROW ===
        g_longitudinal = (msg.throttle_pct - msg.brake_pct) / 100.0 * 2.0
        if abs(g_longitudinal) > 0.1:
            g_arrow = Marker()
            g_arrow.header.frame_id = "f1_car"
            g_arrow.header.stamp = now
            g_arrow.ns = "g_force"
            g_arrow.id = marker_id; marker_id += 1
            g_arrow.type = Marker.ARROW
            g_arrow.action = Marker.ADD
            
            start = Point()
            start.x = car_x
            start.y = 0.0
            start.z = 0.7
            
            end = Point()
            end.x = car_x + g_longitudinal
            end.y = 0.0
            end.z = 0.7
            
            g_arrow.points = [start, end]
            g_arrow.scale.x = 0.15
            g_arrow.scale.y = 0.3
            if g_longitudinal > 0:
                g_arrow.color.r = 0.0
                g_arrow.color.g = 1.0
                g_arrow.color.b = 0.0
            else:
                g_arrow.color.r = 1.0
                g_arrow.color.g = 0.0
                g_arrow.color.b = 0.0
            g_arrow.color.a = 0.9
            markers.markers.append(g_arrow)
        
        self.marker_pub.publish(markers)
        
        if self.msg_count % 50 == 0:
            self.get_logger().info(
                f'{int(msg.speed_kph)} km/h | G{msg.gear} | {int(msg.rpm)} RPM'
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
        marker.color.a = 0.95
        
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
