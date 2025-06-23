using GLib;

public class BinaryExporter : Object {
    // Binary format specification:
    //
    // Header (32 bytes):
    // - Magic number: 4 bytes ("TRAJ")
    // - Version: 2 bytes (uint16, currently 1)
    // - Reserved: 2 bytes (padding)
    // - Trajectory count: 4 bytes (uint32)
    // - Export timestamp: 8 bytes (int64, Unix timestamp in ms)
    // - Total position count: 4 bytes (uint32)
    // - Reserved: 8 bytes (padding for future use)
    //
    // For each trajectory:
    // - Trajectory ID: 4 bytes (uint32)
    // - Position count: 4 bytes (uint32)
    // - Duration in ms: 8 bytes (int64)
    // - Positions: position_count * 24 bytes each
    //   - X coordinate: 8 bytes (double)
    //   - Y coordinate: 8 bytes (double)
    //   - Timestamp: 8 bytes (int64, Unix timestamp in ms)

    private const string MAGIC_NUMBER = "TRAJ";
    private const uint16 FORMAT_VERSION = 1;

    public static bool export_trajectories_binary(Trajectory[] trajectories, int trajectory_count) {
        if (trajectory_count == 0) {
            print("No trajectories to export\n");
            return false;
        }

        try {
            var now = new DateTime.now_local();
            var filename = "trajectories_%04d%02d%02d_%02d%02d%02d.traj".printf(
                now.get_year(),
                now.get_month(),
                now.get_day_of_month(),
                now.get_hour(),
                now.get_minute(),
                now.get_second()
            );

            var file = File.new_for_path(filename);
            var file_stream = file.create(FileCreateFlags.NONE);
            var data_stream = new DataOutputStream(file_stream);

            data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);
            write_header(data_stream, trajectory_count, now, trajectories);
            for (int i = 0; i < trajectory_count; i++) {
                write_trajectory(data_stream, trajectories[i], i + 1);
            }

            data_stream.close();

            var file_size = file.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE).get_size();
            var total_positions = calculate_total_positions(trajectories, trajectory_count);

            print("Trajectories exported to binary format: %s\n".printf(filename));
            print("File size: %lld bytes (%.2f KB)\n".printf(file_size, file_size / 1024.0));
            print("Exported %d trajectories with %d total positions\n".printf(trajectory_count, total_positions));
            print("Average bytes per position: %.2f\n".printf((double)file_size / total_positions));

            return true;

        } catch (Error e) {
            print("Error exporting trajectories to binary format: %s\n".printf(e.message));
            return false;
        }
    }

    private static void write_header(
        DataOutputStream stream,
        int trajectory_count,
        DateTime export_time,
        Trajectory[] trajectories
    ) {
        stream.put_string(MAGIC_NUMBER);
        stream.put_uint16(FORMAT_VERSION);
        stream.put_uint16(0);
        stream.put_uint32((uint32)trajectory_count);
        var timestamp_ms = export_time.to_unix() * 1000 + export_time.get_microsecond() / 1000;
        stream.put_int64(timestamp_ms);
        var total_positions = calculate_total_positions(trajectories, trajectory_count);
        stream.put_uint32((uint32)total_positions);
        stream.put_uint64(0);
    }

    private static void write_trajectory(DataOutputStream stream, Trajectory trajectory, int id) {
        stream.put_uint32((uint32)id);
        var position_count = trajectory.get_size();
        stream.put_uint32((uint32)position_count);
        stream.put_int64(trajectory.get_duration_ms());
        for (int i = 0; i < position_count; i++) {
            var pos = trajectory.get_position(i);
            if (pos != null) {
                uint64 x_bits = double_to_uint64_bits(pos.x);
                stream.put_uint64(x_bits);
                uint64 y_bits = double_to_uint64_bits(pos.y);
                stream.put_uint64(y_bits);
                stream.put_int64(pos.timestamp);
            }
        }
    }

    private static uint64 double_to_uint64_bits(double value) {
        uint64* ptr = (uint64*)(&value);
        return *ptr;
    }

    private static double uint64_bits_to_double(uint64 bits) {
        double* ptr = (double*)(&bits);
        return *ptr;
    }

    private static int calculate_total_positions(Trajectory[] trajectories, int trajectory_count) {
        int total = 0;
        for (int i = 0; i < trajectory_count; i++) {
            total += trajectories[i].get_size();
        }
        return total;
    }

    // Utility method to read binary format (for verification/debugging)
    public static bool read_trajectories_binary(string filename) {
        try {
            var file = File.new_for_path(filename);
            if (!file.query_exists()) {
                print("File does not exist: %s\n", filename);
                return false;
            }

            var file_stream = file.read();
            var data_stream = new DataInputStream(file_stream);
            data_stream.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);

            // Read and verify header
            var magic = new uint8[4];
            data_stream.read(magic);
            string magic_str = (string)magic;

            if (magic_str != MAGIC_NUMBER) {
                print("Invalid file format - magic number mismatch\n");
                return false;
            }

            var version = data_stream.read_uint16();
            var reserved1 = data_stream.read_uint16();
            var trajectory_count = data_stream.read_uint32();
            var timestamp = data_stream.read_int64();
            var total_positions = data_stream.read_uint32();
            var reserved2 = data_stream.read_uint64();

            print("Binary file info:\n");
            print("  Version: %u\n", version);
            print("  Trajectory count: %u\n", trajectory_count);
            print("  Total positions: %u\n", total_positions);
            print("  Export timestamp: %lld\n", timestamp);

            // Read trajectories (just headers for verification)
            for (uint32 i = 0; i < trajectory_count; i++) {
                var traj_id = data_stream.read_uint32();
                var pos_count = data_stream.read_uint32();
                var duration = data_stream.read_int64();

                print("  Trajectory %u: %u positions, %lld ms duration\n",
                      traj_id, pos_count, duration);

                data_stream.skip(pos_count * 24);
            }

            data_stream.close();
            return true;

        } catch (Error e) {
            print("Error reading binary file: %s\n", e.message);
            return false;
        }
    }
}
