function attachCurrentUser(req, res, next) {
  res.locals.currentUser = req.user || null;
  next();
}

function requireAuth(req, res, next) {
  if (req.isAuthenticated && req.isAuthenticated()) return next();
  return res.redirect("/sign-in");
}

function requireRole(role) {
  return (req, res, next) => {
    if (!(req.isAuthenticated && req.isAuthenticated())) return res.redirect("/sign-in");
    if (!req.user || req.user.role !== role) return res.status(403).send("Forbidden");
    return next();
  };
}

module.exports = { attachCurrentUser, requireAuth, requireRole };

