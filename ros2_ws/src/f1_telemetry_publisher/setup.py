from setuptools import setup

package_name = 'f1_telemetry_publisher'

setup(
    name=package_name,
    version='0.0.1',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Bob',
    maintainer_email='you@example.com',
    description='F1 Telemetry ROS 2 Publisher',
    license='MIT',
    entry_points={
        'console_scripts': [
            'can_publisher = f1_telemetry_publisher.can_publisher:main',
            'visualizer = f1_telemetry_publisher.visualizer:main',
            'tf_publisher = f1_telemetry_publisher.tf_publisher:main',
        ],
    },
)
