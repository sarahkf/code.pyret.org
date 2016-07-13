provide *
import string-dict as SD
import file("../../../pyret/src/arr/compiler/compile-structs.arr") as CS
import file("../../../pyret/src/arr/compiler/compile-lib.arr") as CL
import file("../../../pyret/src/arr/compiler/repl.arr") as R
import file("../../../pyret/src/arr/compiler/js-of-pyret.arr") as JSP

fun make-dep(raw-dep):
 if raw-dep.import-type == "builtin":
    CS.builtin(raw-dep.name)
  else:
    CS.dependency(raw-dep.protocol, raw-array-to-list(raw-dep.args))
  end
end

fun get-builtin-loadable(raw, uri) -> CL.Loadable:
  provs = CS.provides-from-raw-provides(uri, {
    uri: uri,
    values: raw-array-to-list(raw.get-raw-value-provides()),
    aliases: raw-array-to-list(raw.get-raw-alias-provides()),
    datatypes: raw-array-to-list(raw.get-raw-datatype-provides())
  })
  CL.module-as-string(
      provs,
      CS.minimal-builtins,
      CS.ok(JSP.ccp-string(raw.get-raw-compiled())))
end

fun get-builtin-modules(builtin-mods) block:
  modules = [SD.mutable-string-dict: ]
  for each(b from builtin-mods):
    modules.set-now(b.uri, get-builtin-loadable(b.raw, b.uri))
  end
  modules
end

fun make-builtin-js-locator(builtin-name, raw):
  {
    method needs-compile(_, _): false end,
    method get-modified-time(self):
      0
    end,
    method get-options(self, options):
      options.{ check-mode: false }
    end,
    method get-module(_):
      raise("Should never fetch source for builtin module " + builtin-name)
    end,
    method get-extra-imports(self):
      CS.standard-imports
    end,
    method get-dependencies(_):
      deps = raw.get-raw-dependencies()
      raw-array-to-list(deps).map(make-dep)
    end,
    method get-native-modules(_):
      natives = raw.get-raw-native-modules()
      raw-array-to-list(natives).map(CS.requirejs)
    end,
    method get-globals(_):
      CS.standard-globals
    end,

    method uri(_): "builtin://" + builtin-name end,
    method name(_): builtin-name end,

    method set-compiled(_, _): nothing end,
    method get-compiled(self):
      provs = CS.provides-from-raw-provides(self.uri(), {
        uri: self.uri(),
        values: raw-array-to-list(raw.get-raw-value-provides()),
        aliases: raw-array-to-list(raw.get-raw-alias-provides()),
        datatypes: raw-array-to-list(raw.get-raw-datatype-provides())
      })
      some(CL.module-as-string(provs, CS.minimal-builtins, CS.ok(JSP.ccp-string(raw.get-raw-compiled()))))
    end,

    method _equals(self, other, req-eq):
      req-eq(self.uri(), other.uri())
    end
  }
end

fun make-repl(builtin-mods, runtime, realm, finder):
  modules = get-builtin-modules(builtin-mods)
  repl = R.make-repl(runtime, modules, realm, "cpo-context-currently-unused", finder)
  repl
end
