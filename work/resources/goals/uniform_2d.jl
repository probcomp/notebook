struct Uniform2D <: AssessableAtomicGenerator{Point} end

function Gen.simulate(::Uniform2D, xmin::Real, xmax::Real, ymin::Real, ymax::Real)
    x = Gen.simulate(UniformContinuous(), xmin, xmax)
    y = Gen.simulate(UniformContinuous(), ymin, ymax)
    Point(x, y)
end

function Gen.logpdf(::Uniform2D, point::Point, xmin::Real, xmax::Real, ymin::Real, ymax::Real)
    logp_x = Gen.logpdf(UniformContinuous(), point.x, xmin, xmax)
    logp_y = Gen.logpdf(UniformContinuous(), point.y, ymin, ymax)
    logp_x + logp_y
end

register_primitive(:uniform_2d, Uniform2D)