-- Split a filename into [root, dir, basename, ext], unix version
-- 'root' is just a slash, or nothing.


function split_path(filename)
  return string.find(filename, "^(/?)(.*/?)([^.]*)(\.[^.]*)$")
end

exports.dirname = function(path) {
  local a, b, root, dir = split_path(path)

  if (!root && !dir) {
    // No dirname whatsoever
    return '.';
  }

  if (dir) {
    // It has a dirname, strip trailing slash
    dir = dir.substring(0, dir.length - 1);
  }

  return root + dir;
};

return {
  dirname = dirname
}
