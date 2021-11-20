from manim import *


class AnimateExample(Scene):
    def construct(self):
        self.camera.background_color = WHITE
        ## view 1
        object_with_no_label1_v1_points = [
            [-4.5511111111111, 1.44, 0],
            [-6.1511111111111, 0.48, 0],
            [-3.5911111111111, 0.16, 0],
        ]
        object_with_no_label1_v1 = Polygon(
            *object_with_no_label1_v1_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.827, 0.827, 0.827]),
            fill_opacity=1,
        )
        circle_v1 = Circle(
            radius=0.64,
            arc_center=[-3.2711111111111, -1.12, 0.0],
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.565, 0.933, 0.565]),
            fill_opacity=1,
        )
        oktagon_v1_points = [
            [0.24888888888889, -0.8, 0],
            [-0.032291111111111, -0.12118, 0],
            [-0.71111111111111, 0.16, 0],
            [-1.3899311111111, -0.12118, 0],
            [-1.6711111111111, -0.8, 0],
            [-1.3899311111111, -1.47882, 0],
            [-0.71111111111111, -1.76, 0],
            [-0.032291111111111, -1.47882, 0],
        ]
        oktagon_v1 = Polygon(
            *oktagon_v1_points,
            color=rgb_to_color([0.0, 0.392, 0.0]),
        )
        square_v1_points = [
            [-6.4711111111111, -0.48, 0],
            [-6.4711111111111, -1.76, 0],
            [-5.1911111111111, -1.76, 0],
            [-5.1911111111111, -0.48, 0],
        ]
        square_v1 = Polygon(
            *square_v1_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([1.0, 1.0, 0.878]),
            fill_opacity=1,
        )
        self.play(
            Create(object_with_no_label1_v1),
            Create(circle_v1),
            Create(oktagon_v1),
            Create(square_v1),
        )
        ## view 2
        circle_v2 = Circle(
            radius=0.64,
            arc_center=[-3.2711111111111, -2.4, 0.0],
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.565, 0.933, 0.565]),
            fill_opacity=1,
        )
        oktagon_v2_points = [
            [0.24888888888889, -0.8, 0],
            [-0.032291111111111, -0.12118, 0],
            [-0.71111111111111, 0.16, 0],
            [-1.3899311111111, -0.12118, 0],
            [-1.6711111111111, -0.8, 0],
            [-1.3899311111111, -1.47882, 0],
            [-0.71111111111111, -1.76, 0],
            [-0.032291111111111, -1.47882, 0],
        ]
        oktagon_v2 = Polygon(
            *oktagon_v2_points,
            stroke_opacity=0.0,
            fill_color=rgb_to_color([0.565, 0.933, 0.565]),
            fill_opacity=1,
        )
        square_v2_points = [
            [-6.7362031111111, -1.12, 0],
            [-5.8311071111111, -2.025096, 0],
            [-4.9260111111111, -1.12, 0],
            [-5.8311071111111, -0.2149, 0],
        ]
        square_v2 = Polygon(
            *square_v2_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([1.0, 1.0, 0.878]),
            fill_opacity=1,
        )
        self.play(
            FadeOut(object_with_no_label1_v1),
            Transform(circle_v1, circle_v2),
            Transform(oktagon_v1, oktagon_v2),
            Transform(square_v1, square_v2),
        )
        self.remove(object_with_no_label1_v1)
        self.remove(circle_v1)
        self.remove(oktagon_v1)
        self.remove(square_v1)
        ## view 3
        object_with_no_label1_v3_points = [
            [-4.5511111111111, 1.44, 0],
            [-6.1511111111111, 0.48, 0],
            [-3.5911111111111, 0.16, 0],
        ]
        object_with_no_label1_v3 = Polygon(
            *object_with_no_label1_v3_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.827, 0.827, 0.827]),
            fill_opacity=1,
        )
        circle_v3 = Circle(
            radius=0.64,
            arc_center=[-3.2711111111111, -1.12, 0.0],
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.565, 0.933, 0.565]),
            fill_opacity=1,
        )
        square_v3_points = [
            [-6.4711111111111, -0.48, 0],
            [-6.4711111111111, -1.76, 0],
            [-5.1911111111111, -1.76, 0],
            [-5.1911111111111, -0.48, 0],
        ]
        square_v3 = Polygon(
            *square_v3_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([1.0, 1.0, 0.878]),
            fill_opacity=1,
        )
        object_with_no_label2_v3_points = [
            [-2.6311111111111, 1.12, 0],
            [-1.6711111111111, -0.48, 0],
            [-1.0311111111111, 1.12, 0],
        ]
        object_with_no_label2_v3 = Polygon(
            *object_with_no_label2_v3_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.827, 0.827, 0.827]),
            fill_opacity=1,
        )
        triangle_v3_points = [
            [-6.7911111111111, -3.68, 0],
            [-5.5111111111111, -2.4, 0],
            [-4.5511111111111, -3.68, 0],
        ]
        triangle_v3 = Polygon(
            *triangle_v3_points,
            color=rgb_to_color([0.0, 0.0, 0.0]),
            fill_color=rgb_to_color([0.678, 0.847, 0.902]),
            fill_opacity=1,
        )
        oktagon_v3_points = [
            [0.24888888888889, -0.8, 0],
            [-0.032291111111111, -0.12118, 0],
            [-0.71111111111111, 0.16, 0],
            [-1.3899311111111, -0.12118, 0],
            [-1.6711111111111, -0.8, 0],
            [-1.3899311111111, -1.47882, 0],
            [-0.71111111111111, -1.76, 0],
            [-0.032291111111111, -1.47882, 0],
        ]
        oktagon_v3 = Polygon(
            *oktagon_v3_points,
            color=rgb_to_color([0.0, 0.392, 0.0]),
        )
        self.play(
            Create(object_with_no_label1_v3),
            Transform(circle_v2, circle_v3),
            Transform(square_v2, square_v3),
            Create(object_with_no_label2_v3),
            Create(triangle_v3),
            Transform(oktagon_v2, oktagon_v3),
        )
        self.remove(circle_v2)
        self.remove(square_v2)
        self.remove(oktagon_v2)
        ## view 4
        self.play(
            FadeOut(object_with_no_label1_v3),
            FadeOut(circle_v3),
            FadeOut(square_v3),
            FadeOut(oktagon_v3),
        )
        self.remove(object_with_no_label1_v3)
        self.remove(circle_v3)
        self.remove(square_v3)
        self.remove(oktagon_v3)
        ## view 5
        self.play(
            FadeOut(triangle_v3),
            FadeOut(object_with_no_label2_v3),
        )
        self.remove(triangle_v3)
        self.remove(object_with_no_label2_v3)
