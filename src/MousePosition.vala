using GLib;

public struct MousePosition {
    public double x;
    public double y;
    public int64 timestamp;

    public MousePosition(double x, double y, int64 timestamp) {
        this.x = x;
        this.y = y;
        this.timestamp = timestamp;
    }
}

public class Trajectory : Object {
    private MousePosition[] positions;
    private int position_count;

    public Trajectory() {
        positions = new MousePosition[1000];
        position_count = 0;
    }

    public void add_position(double x, double y, int64 timestamp) {
        if (position_count >= positions.length) {
            var new_positions = new MousePosition[positions.length * 2];
            for (int i = 0; i < positions.length; i++) {
                new_positions[i] = positions[i];
            }
            positions = new_positions;
        }

        positions[position_count] = MousePosition(x, y, timestamp);
        position_count++;
    }

    public void clear() {
        position_count = 0;
    }

    public int get_size() {
        return position_count;
    }

    public MousePosition? get_position(int index) {
        if (index >= 0 && index < position_count) {
            return positions[index];
        }
        return null;
    }

    public MousePosition[] get_all_positions() {
        var result = new MousePosition[position_count];
        for (int i = 0; i < position_count; i++) {
            result[i] = positions[i];
        }
        return result;
    }

    public int64 get_duration_ms() {
        if (position_count < 2) return 0;
        return positions[position_count - 1].timestamp - positions[0].timestamp;
    }
}
