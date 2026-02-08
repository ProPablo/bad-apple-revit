using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    public static class MathExtensions
    {

        /// <summary>
        /// Debug helper: Print quaternion euler angles (in degrees)
        /// </summary>
        public static void PrintQuaternionEuler(this Quaternion q)
        {
            // Convert quaternion to Euler angles (XYZ order)
            float sinr_cosp = 2 * (q.W * q.X + q.Y * q.Z);
            float cosr_cosp = 1 - 2 * (q.X * q.X + q.Y * q.Y);
            float roll = (float)Math.Atan2(sinr_cosp, cosr_cosp);

            float sinp = 2 * (q.W * q.Y - q.Z * q.X);
            float pitch;
            if (Math.Abs(sinp) >= 1)
            {
                float sign = sinp >= 0 ? 1f : -1f;
                pitch = sign * (float)(Math.PI / 2);

            }
            else
                pitch = (float)Math.Asin(sinp);

            float siny_cosp = 2 * (q.W * q.Z + q.X * q.Y);
            float cosy_cosp = 1 - 2 * (q.Y * q.Y + q.Z * q.Z);
            float yaw = (float)Math.Atan2(siny_cosp, cosy_cosp);
            string thing = $"Euler Angles (degrees): Roll={roll * 180 / Math.PI:F2}, Pitch={pitch * 180 / Math.PI:F2}, Yaw={yaw * 180 / Math.PI:F2}";

            Console.WriteLine(thing);
        }
    }
}
