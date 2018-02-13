import numpy as np

from venture.lite.covariance import Kernel
from venture.lite.utils import override


class change_point(Kernel):
  """Change point between kernels K and H."""

  @override(Kernel)
  def __init__(self, location, scale, K, H):
    self._K = K
    self._H = H
    self._location = location
    self._scale = scale

  @override(Kernel)
  def __repr__(self):
    return 'CP(%r, %r)' % (self._K, self._H)

  @property
  @override(Kernel)
  def parameters(self):
    K_shape = ParamProduct(self._K.parameters)
    H_shape = ParamProduct(self._H.parameters)
    return [K_shape, H_shape]

  def _change(self, x, location, scale):
    return 0.5 *(1 + np.tanh((location-x)/scale))

  @override(Kernel)
  def f(self, X, Y):
    # XXX only works on one 1-d input.
    """ Implementing Lloyd et al., 2014, Appendix A2.

    CP(k,h) = sig_1 * k + sig_2 * h

    where

    sig_1 = change(x) * change(y) and

    sig_2 = (1 - change(x)) * (1 - change(y)).

    Note the use of lower case k and h above, to indicate actual kernels, that
    is covariance functions with scalar input.
    """
    K = self._K
    H = self._H

    change_x = self._change(X, self._location, self._scale)
    change_y = self._change(Y, self._location, self._scale)
    sig_1 = np.outer(change_x, change_y)
    sig_2 = np.outer(1 - change_x, 1 - change_y)
    return np.multiply(sig_1, K.f(X, Y)) + np.multiply(sig_2, H.f(X, Y))

  @override(Kernel)
  def df_theta(self, X, Y):
    raise NotImplementedError

  @override(Kernel)
  def df_x(self, x, Y):
    raise NotImplementedError
