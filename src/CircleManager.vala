using GLib;

public class CircleManager : Object {
    public const double CIRCLE_RADIUS = 20.0;
    private const double EDGE_PADDING = 5.0;

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
        double min_x = CIRCLE_RADIUS + EDGE_PADDING;
        double max_x = canvas_width - CIRCLE_RADIUS - EDGE_PADDING;
        double min_y = CIRCLE_RADIUS + EDGE_PADDING;
        double max_y = canvas_height - CIRCLE_RADIUS - EDGE_PADDING;
        circle_x = min_x + (max_x - min_x) * GLib.Random.next_double();
        circle_y = min_y + (max_y - min_y) * GLib.Random.next_double();
        print("New circle generated at (%.0f, %.0f) with canvas size (%d, %d)\n",
              circle_x, circle_y, canvas_width, canvas_height);
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
