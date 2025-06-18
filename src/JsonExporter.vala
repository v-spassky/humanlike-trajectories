using GLib;

public class JsonExporter : Object {

    public static bool export_trajectories(Trajectory[] trajectories, int trajectory_count) {
        if (trajectory_count == 0) {
            print("No trajectories to export\n");
            return false;
        }

        try {
            var now = new DateTime.now_local();
            var filename = "trajectories_%04d%02d%02d_%02d%02d%02d.json".printf(
                now.get_year(),
                now.get_month(),
                now.get_day_of_month(),
                now.get_hour(),
                now.get_minute(),
                now.get_second()
            );

            string json_content = build_json_string(trajectories, trajectory_count, now);

            var file = File.new_for_path(filename);
            var file_stream = file.create(FileCreateFlags.NONE);
            var data_stream = new DataOutputStream(file_stream);
            data_stream.put_string(json_content);
            data_stream.close();

            print("Trajectories exported to: %s\n".printf(filename));
            print("Exported %d trajectories with total of %d positions\n".printf(
                trajectory_count, 
                calculate_total_positions(trajectories, trajectory_count)
            ));

            return true;

        } catch (Error e) {
            print("Error exporting trajectories: %s\n".printf(e.message));
            return false;
        }
    }

    private static string build_json_string(Trajectory[] trajectories, int trajectory_count, DateTime export_time) {
        var json_builder = new StringBuilder();

        json_builder.append("{\n");
        json_builder.append("  \"export_info\": {\n");
        json_builder.append("    \"timestamp\": \"%s\",\n".printf(export_time.to_string()));
        json_builder.append("    \"trajectory_count\": %d\n".printf(trajectory_count));
        json_builder.append("  },\n");
        json_builder.append("  \"trajectories\": [\n");

        for (int i = 0; i < trajectory_count; i++) {
            var trajectory = trajectories[i];
            append_trajectory_json(json_builder, trajectory, i + 1);

            if (i < trajectory_count - 1) {
                json_builder.append(",");
            }
            json_builder.append("\n");
        }

        json_builder.append("  ]\n");
        json_builder.append("}\n");

        return json_builder.str;
    }

    private static void append_trajectory_json(StringBuilder builder, Trajectory trajectory, int id) {
        builder.append("    {\n");
        builder.append("      \"id\": %d,\n".printf(id));
        builder.append("      \"position_count\": %d,\n".printf(trajectory.get_size()));
        builder.append("      \"duration_ms\": %lld,\n".printf(trajectory.get_duration_ms()));
        builder.append("      \"positions\": [\n");

        for (int j = 0; j < trajectory.get_size(); j++) {
            var pos = trajectory.get_position(j);
            if (pos != null) {
                builder.append("        {\n");
                builder.append("          \"x\": %.2f,\n".printf(pos.x));
                builder.append("          \"y\": %.2f,\n".printf(pos.y));
                builder.append("          \"timestamp\": %lld\n".printf(pos.timestamp));
                builder.append("        }");
                if (j < trajectory.get_size() - 1) {
                    builder.append(",");
                }
                builder.append("\n");
            }
        }

        builder.append("      ]\n");
        builder.append("    }");
    }

    private static int calculate_total_positions(Trajectory[] trajectories, int trajectory_count) {
        int total = 0;
        for (int i = 0; i < trajectory_count; i++) {
            total += trajectories[i].get_size();
        }
        return total;
    }
}
