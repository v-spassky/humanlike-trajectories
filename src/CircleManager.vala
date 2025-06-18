using GLib;

public class CircleManager : Object {
    public const double CIRCLE_RADIUS = 20.0;

    public double? circle_x { get; private set; }
    public double? circle_y { get; private set; }

    public signal void circle_generated(double x, double y);
    public signal void circle_clicked();

    private int canvas_width;
    private int canvas_height;

    public CircleManager() {
        circle_x = null;
        circle_y = null;
    }

    public void set_canvas_size(int width, int height) {
        canvas_width = width;
        canvas_height = height;
    }

    public void generate_new_circle() {
        if (canvas_width <= 0 || canvas_height <= 0) {
            canvas_width = 800;
            canvas_height = 600;
        }

        circle_x = CIRCLE_RADIUS + (canvas_width - 2 * CIRCLE_RADIUS) * GLib.Random.next_double();
        circle_y = CIRCLE_RADIUS + (canvas_height - 2 * CIRCLE_RADIUS) * GLib.Random.next_double();

        print("New circle generated at (%.0f, %.0f)\n", circle_x, circle_y);
        circle_generated(circle_x, circle_y);
    }

    public bool check_click(double x, double y) {
        if (circle_x == null || circle_y == null) {
            return false;
        }

        var dx = x - circle_x;
        var dy = y - circle_y;
        bool hit = (dx * dx + dy * dy <= CIRCLE_RADIUS * CIRCLE_RADIUS);

        if (hit) {
            print("Circle clicked successfully!\n");
            circle_clicked();
        }

        return hit;
    }

    public bool has_circle() {
        return circle_x != null && circle_y != null;
    }
}
