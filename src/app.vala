using Cairo;
using Gdk;
using Gtk;
using GLib;

public class HumanlikeTrajectories : Gtk.Application {
    private Gtk.DrawingArea area;
    private Gtk.Stack content_stack;
    private Gtk.Button canvas_button;
    private Gtk.Button datasets_button;
    private Gtk.Button settings_button;

    private CircleManager circle_manager;
    private TrajectoryManager trajectory_manager;

    public HumanlikeTrajectories () {
        Object(application_id: "org.vspassky.HumanlikeTrajectories");
        circle_manager = new CircleManager();
        trajectory_manager = new TrajectoryManager();
        setup_manager_signals();
    }

    public static int main (string[] args) {
        return new HumanlikeTrajectories().run(args);
    }

    private void setup_manager_signals() {
        circle_manager.circle_generated.connect((x, y) => {
            trajectory_manager.start_new_trajectory();
            area.queue_draw();
        });
        circle_manager.circle_clicked.connect(() => {
            trajectory_manager.finish_current_trajectory();
            circle_manager.generate_new_circle();
        });
        trajectory_manager.trajectory_completed.connect((total_count) => {
            // Could update UI here if needed
        });
        trajectory_manager.trajectory_started.connect((trajectory_number) => {
            // Could update UI here if needed
        });
    }

    protected override void activate () {
        var window = new Gtk.ApplicationWindow(this);
        window.set_title("Human-like trajectories");
        window.set_default_size(1200, 600);

        content_stack = new Gtk.Stack();
        content_stack.set_hexpand(true);
        content_stack.set_vexpand(true);

        setup_drawing_area();

        var datasets_view = create_datasets_view();
        var settings_view = create_settings_view();

        content_stack.add_named(area, "canvas");
        content_stack.add_named(datasets_view, "datasets");
        content_stack.add_named(settings_view, "settings");
        content_stack.set_visible_child_name("canvas");

        var controls = create_sidebar();

        var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        hbox.append(controls);
        hbox.append(content_stack);

        window.set_child(hbox);
        window.present();

        Idle.add(() => {
            circle_manager.set_canvas_size(area.get_allocated_width(), area.get_allocated_height());
            circle_manager.generate_new_circle();
            return false;
        });
    }

    private void setup_drawing_area() {
        area = new Gtk.DrawingArea();
        area.set_hexpand(true);
        area.set_vexpand(true);
        area.set_draw_func((widget, cr, width, height) => {
            circle_manager.set_canvas_size(width, height);
            if (circle_manager.has_circle()) {
                cr.set_source_rgb(1, 0, 0);
                cr.arc(circle_manager.circle_x, circle_manager.circle_y,
                       CircleManager.CIRCLE_RADIUS, 0, 2 * Math.PI);
                cr.fill();
            }
        });

        var motion = new Gtk.EventControllerMotion();
        motion.motion.connect((x, y) => {
            var now = new DateTime.now_local();
            print("[%02d:%02d:%02d.%03d] Mouse moved to: (%.0f, %.0f)\n",
                now.get_hour(),
                now.get_minute(),
                now.get_second(),
                now.get_microsecond() / 1000,
                x, y
            );
            trajectory_manager.record_position(x, y);
        });
        area.add_controller(motion);

        // Click handling
        var click = new Gtk.GestureClick();
        click.released.connect((n_press, x, y) => {
            circle_manager.check_click(x, y);
        });
        area.add_controller(click);
    }

    private Gtk.Widget create_sidebar() {
        var controls = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        controls.set_size_request(120, -1);
        controls.set_hexpand(false);
        controls.set_vexpand(true);
        controls.get_style_context().add_class("view");

        canvas_button = new Gtk.Button.with_label("Canvas");
        canvas_button.set_hexpand(true);
        canvas_button.get_style_context().add_class("flat");
        canvas_button.clicked.connect(() => {
            content_stack.set_visible_child_name("canvas");
            update_active_tab("canvas");
        });

        datasets_button = new Gtk.Button.with_label("Datasets");
        datasets_button.set_hexpand(true);
        datasets_button.get_style_context().add_class("flat");
        datasets_button.clicked.connect(() => {
            content_stack.set_visible_child_name("datasets");
            update_active_tab("datasets");
        });

        settings_button = new Gtk.Button.with_label("Settings");
        settings_button.set_hexpand(true);
        settings_button.get_style_context().add_class("flat");
        settings_button.clicked.connect(() => {
            content_stack.set_visible_child_name("settings");
            update_active_tab("settings");
        });

        update_active_tab("canvas");

        controls.append(canvas_button);
        controls.append(datasets_button);
        controls.append(settings_button);

        return controls;
    }

    private void update_active_tab(string active_tab) {
        canvas_button.get_style_context().remove_class("suggested-action");
        datasets_button.get_style_context().remove_class("suggested-action");
        settings_button.get_style_context().remove_class("suggested-action");

        switch (active_tab) {
            case "canvas":
                canvas_button.get_style_context().add_class("suggested-action");
                break;
            case "datasets":
                datasets_button.get_style_context().add_class("suggested-action");
                break;
            case "settings":
                settings_button.get_style_context().add_class("suggested-action");
                break;
        }
    }

    private Gtk.Widget create_datasets_view() {
        var scrolled = new Gtk.ScrolledWindow();
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
        main_box.set_margin_start(20);
        main_box.set_margin_end(20);
        main_box.set_margin_top(20);
        main_box.set_margin_bottom(20);

        var traj_label = new Gtk.Label("<b>Recorded Trajectories</b>");
        traj_label.set_use_markup(true);
        traj_label.set_halign(Gtk.Align.START);
        main_box.append(traj_label);

        var traj_listbox = new Gtk.ListBox();
        traj_listbox.set_selection_mode(Gtk.SelectionMode.SINGLE);

        for (int i = 0; i < trajectory_manager.get_trajectory_count(); i++) {
            var trajectory = trajectory_manager.get_trajectory(i);
            if (trajectory != null) {
                var row = new Gtk.ListBoxRow();
                var info_text = "Trajectory %d (%d positions, %lld ms)".printf(
                    i + 1,
                    trajectory.get_size(),
                    trajectory.get_duration_ms()
                );
                var label = new Gtk.Label(info_text);
                label.set_halign(Gtk.Align.START);
                label.set_margin_start(12);
                label.set_margin_end(12);
                label.set_margin_top(8);
                label.set_margin_bottom(8);
                row.set_child(label);
                traj_listbox.append(row);
            }
        }

        main_box.append(traj_listbox);

        var static_label = new Gtk.Label("<b>Static Datasets</b>");
        static_label.set_use_markup(true);
        static_label.set_halign(Gtk.Align.START);
        static_label.set_margin_top(20);
        main_box.append(static_label);

        var listbox = new Gtk.ListBox();
        listbox.set_selection_mode(Gtk.SelectionMode.SINGLE);

        string[] datasets = {
            "Training Dataset A (1,234 samples)",
            "Validation Dataset B (456 samples)",
            "Test Dataset C (789 samples)",
            "Custom Dataset D (2,345 samples)",
            "Benchmark Dataset E (987 samples)"
        };

        foreach (string dataset in datasets) {
            var row = new Gtk.ListBoxRow();
            var label = new Gtk.Label(dataset);
            label.set_halign(Gtk.Align.START);
            label.set_margin_start(12);
            label.set_margin_end(12);
            label.set_margin_top(8);
            label.set_margin_bottom(8);
            row.set_child(label);
            listbox.append(row);
        }

        main_box.append(listbox);
        scrolled.set_child(main_box);
        return scrolled;
    }

    private Gtk.Widget create_settings_view() {
        var scrolled = new Gtk.ScrolledWindow();
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
        box.set_margin_start(20);
        box.set_margin_end(20);
        box.set_margin_top(20);
        box.set_margin_bottom(20);

        var traj_label = new Gtk.Label("<b>Trajectory Settings</b>");
        traj_label.set_use_markup(true);
        traj_label.set_halign(Gtk.Align.START);
        box.append(traj_label);

        var traj_buttons_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);

        var export_button = new Gtk.Button.with_label("Export Trajectories");
        export_button.get_style_context().add_class("suggested-action");
        export_button.clicked.connect(() => {
            var trajectories = trajectory_manager.get_all_trajectories();
            JsonExporter.export_trajectories(trajectories, trajectory_manager.get_trajectory_count());
        });

        var clear_button = new Gtk.Button.with_label("Clear All Trajectories");
        clear_button.get_style_context().add_class("destructive-action");
        clear_button.clicked.connect(() => {
            trajectory_manager.clear_all_trajectories();
        });

        traj_buttons_box.append(export_button);
        traj_buttons_box.append(clear_button);
        box.append(traj_buttons_box);

        var general_label = new Gtk.Label("<b>General Settings</b>");
        general_label.set_use_markup(true);
        general_label.set_halign(Gtk.Align.START);
        general_label.set_margin_top(20);
        box.append(general_label);

        var enable_sound = new Gtk.CheckButton.with_label("Enable sound effects");
        enable_sound.set_active(true);
        box.append(enable_sound);

        var auto_save = new Gtk.CheckButton.with_label("Auto-save progress");
        auto_save.set_active(false);
        box.append(auto_save);

        var perf_label = new Gtk.Label("<b>Performance</b>");
        perf_label.set_use_markup(true);
        perf_label.set_halign(Gtk.Align.START);
        perf_label.set_margin_top(20);
        box.append(perf_label);

        var quality_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        var quality_label = new Gtk.Label("Render quality:");
        quality_label.set_halign(Gtk.Align.START);
        var quality_combo = new Gtk.ComboBoxText();
        quality_combo.append_text("Low");
        quality_combo.append_text("Medium");
        quality_combo.append_text("High");
        quality_combo.set_active(1);
        quality_box.append(quality_label);
        quality_box.append(quality_combo);
        box.append(quality_box);

        var fps_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        var fps_label = new Gtk.Label("Max FPS:");
        fps_label.set_halign(Gtk.Align.START);
        var fps_spin = new Gtk.SpinButton.with_range(30, 144, 1);
        fps_spin.set_value(60);
        fps_box.append(fps_label);
        fps_box.append(fps_spin);
        box.append(fps_box);

        var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        button_box.set_margin_top(30);
        var reset_button = new Gtk.Button.with_label("Reset to Defaults");
        var apply_button = new Gtk.Button.with_label("Apply Changes");
        apply_button.get_style_context().add_class("suggested-action");
        button_box.append(reset_button);
        button_box.append(apply_button);
        box.append(button_box);

        scrolled.set_child(box);
        return scrolled;
    }
}
