using GLib;

public class TrajectoryManager : Object {
    private Trajectory[] trajectories;
    private int trajectory_count;
    private Trajectory current_trajectory;
    private bool tracking_active;

    public signal void trajectory_completed(int total_count);
    public signal void trajectory_started(int trajectory_number);

    public TrajectoryManager() {
        trajectories = new Trajectory[100];
        trajectory_count = 0;
        current_trajectory = new Trajectory();
        tracking_active = false;
    }

    public void start_new_trajectory() {
        current_trajectory = new Trajectory();
        tracking_active = true;

        print("Started tracking trajectory #%d\n", trajectory_count + 1);
        trajectory_started(trajectory_count + 1);
    }

    public void record_position(double x, double y) {
        if (!tracking_active) return;

        var now = new DateTime.now_local();
        int64 timestamp = now.to_unix() * 1000 + now.get_microsecond() / 1000;
        current_trajectory.add_position(x, y, timestamp);
    }

    public void finish_current_trajectory() {
        if (!tracking_active || current_trajectory.get_size() == 0) {
            return;
        }

        if (trajectory_count >= trajectories.length) {
            var new_trajectories = new Trajectory[trajectories.length * 2];
            for (int i = 0; i < trajectories.length; i++) {
                new_trajectories[i] = trajectories[i];
            }
            trajectories = new_trajectories;
        }

        trajectories[trajectory_count] = current_trajectory;
        trajectory_count++;
        tracking_active = false;

        print("Trajectory #%d completed with %d positions (duration: %lld ms)\n", 
              trajectory_count, 
              current_trajectory.get_size(),
              current_trajectory.get_duration_ms());

        trajectory_completed(trajectory_count);
    }

    public void clear_all_trajectories() {
        trajectory_count = 0;
        tracking_active = false;
        print("All trajectories cleared\n");
    }

    public int get_trajectory_count() {
        return trajectory_count;
    }

    public Trajectory? get_trajectory(int index) {
        if (index >= 0 && index < trajectory_count) {
            return trajectories[index];
        }
        return null;
    }

    public Trajectory[] get_all_trajectories() {
        var result = new Trajectory[trajectory_count];
        for (int i = 0; i < trajectory_count; i++) {
            result[i] = trajectories[i];
        }
        return result;
    }

    public int get_total_position_count() {
        int total = 0;
        for (int i = 0; i < trajectory_count; i++) {
            total += trajectories[i].get_size();
        }
        return total;
    }

    public bool is_tracking_active() {
        return tracking_active;
    }
}
