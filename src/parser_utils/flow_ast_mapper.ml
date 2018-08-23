(**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

let map_opt: 'node. ('node -> 'node) -> 'node option -> 'node option =
  fun map opt ->
    match opt with
    | Some item ->
      let item' = map item in
      if item == item' then opt else Some item'
    | None -> opt

let id: 'node 'a. ('node -> 'node) -> 'node -> 'a -> ('node -> 'a) -> 'a =
  fun map item same diff ->
    let item' = map item in
    if item == item' then same else diff item'

let map_loc: 'node. ('node -> 'node) -> (Loc.t * 'node) -> (Loc.t * 'node) =
  fun map same ->
    let loc, item = same in
    id map item same (fun diff -> (loc, diff))

class mapper = object(this)
  method program (program: (Loc.t, Loc.t) Flow_ast.program) =
    let (loc, statements, comments) = program in
    let statements' = this#toplevel_statement_list statements in
    let comments' = ListUtils.ident_map (this#comment) comments in
    if statements == statements' && comments == comments' then program
    else loc, statements', comments'

  method statement (stmt: (Loc.t, Loc.t) Flow_ast.Statement.t) =
    let open Flow_ast.Statement in
    match stmt with
    | (loc, Block block) ->
      id this#block block stmt (fun block -> loc, Block block)

    | (loc, Break break) ->
      id this#break break stmt (fun break -> loc, Break break)

    | (loc, ClassDeclaration cls) ->
      id this#class_ cls stmt (fun cls -> loc, ClassDeclaration cls)

    | (loc, Continue cont) ->
      id this#continue cont stmt (fun cont -> loc, Continue cont)

    | (_loc, Debugger) ->
      this#debugger ();
      stmt

    | (loc, DeclareClass stuff) ->
      id this#declare_class stuff stmt (fun stuff -> loc, DeclareClass stuff)

    | (loc, DeclareExportDeclaration decl) ->
      id (this#declare_export_declaration loc) decl stmt (fun decl -> loc, DeclareExportDeclaration decl)

    | (loc, DeclareFunction stuff) ->
      id this#declare_function stuff stmt (fun stuff -> loc, DeclareFunction stuff)

    | (loc, DeclareInterface stuff) ->
      id this#declare_interface stuff stmt (fun stuff -> loc, DeclareInterface stuff)

    | (loc, DeclareModule m) ->
      id (this#declare_module loc) m stmt (fun m -> loc, DeclareModule m)

    | (loc, DeclareTypeAlias stuff) ->
      id this#declare_type_alias stuff stmt (fun stuff -> loc, DeclareTypeAlias stuff)

    | (loc, DeclareVariable stuff) ->
      id this#declare_variable stuff stmt (fun stuff -> loc, DeclareVariable stuff)

    | (loc, DeclareModuleExports annot) ->
      id (this#declare_module_exports loc) annot stmt (fun annot -> loc, DeclareModuleExports annot)

    | (loc, DoWhile stuff) ->
      id this#do_while stuff stmt (fun stuff -> loc, DoWhile stuff)

    | (_loc, Empty) ->
      this#empty ();
      stmt

    | (loc, ExportDefaultDeclaration decl) ->
      id (this#export_default_declaration loc) decl stmt (fun decl -> loc, ExportDefaultDeclaration decl)

    | (loc, ExportNamedDeclaration decl) ->
      id (this#export_named_declaration loc) decl stmt (fun decl -> loc, ExportNamedDeclaration decl)

    | (loc, Expression expr) ->
      id this#expression_statement expr stmt (fun expr -> loc, Expression expr)

    | (loc, For for_stmt) ->
      id this#for_statement for_stmt stmt (fun for_stmt -> loc, For for_stmt)

    | (loc, ForIn stuff) ->
      id this#for_in_statement stuff stmt (fun stuff -> loc, ForIn stuff)

    | (loc, ForOf stuff) ->
      id this#for_of_statement stuff stmt (fun stuff -> loc, ForOf stuff)

    | (loc, FunctionDeclaration func) ->
      id this#function_declaration func stmt (fun func -> loc, FunctionDeclaration func)

    | (loc, If if_stmt) ->
      id this#if_statement if_stmt stmt (fun if_stmt -> loc, If if_stmt)

    | (loc, ImportDeclaration decl) ->
      id (this#import_declaration loc) decl stmt (fun decl -> loc, ImportDeclaration decl)

    | (loc, InterfaceDeclaration stuff) ->
      id this#interface_declaration stuff stmt (fun stuff -> loc, InterfaceDeclaration stuff)

    | (loc, Labeled label) ->
      id this#labeled_statement label stmt (fun label -> loc, Labeled label)

    | (loc, OpaqueType otype) ->
      id this#opaque_type otype stmt (fun otype -> loc, OpaqueType otype)

    | (loc, Return ret) ->
      id this#return ret stmt (fun ret -> loc, Return ret)

    | (loc, Switch switch) ->
      id this#switch switch stmt (fun switch -> loc, Switch switch)

    | (loc, Throw throw) ->
      id this#throw throw stmt (fun throw -> loc, Throw throw)

    | (loc, Try try_stmt) ->
      id this#try_catch try_stmt stmt (fun try_stmt -> loc, Try try_stmt)

    | (loc, VariableDeclaration decl) ->
      id this#variable_declaration decl stmt (fun decl -> loc, VariableDeclaration decl)

    | (loc, While stuff) ->
      id this#while_ stuff stmt (fun stuff -> loc, While stuff)

    | (loc, With stuff) ->
      id this#with_ stuff stmt (fun stuff -> loc, With stuff)

    | (loc, TypeAlias stuff) ->
      id this#type_alias stuff stmt (fun stuff -> loc, TypeAlias stuff)

    (* TODO: Flow specific stuff *)
    | (_loc, DeclareOpaqueType _) -> stmt

  method comment (c: Loc.t Flow_ast.Comment.t) = c

  method expression (expr: (Loc.t, Loc.t) Flow_ast.Expression.t) =
    let open Flow_ast.Expression in
    match expr with
    | _, This -> expr
    | _, Super -> expr
    | loc, Array x -> id this#array x expr (fun x -> loc, Array x)
    | loc, ArrowFunction x -> id this#arrow_function x expr (fun x -> loc, ArrowFunction x)
    | loc, Assignment x -> id this#assignment x expr (fun x -> loc, Assignment x)
    | loc, Binary x -> id this#binary x expr (fun x -> loc, Binary x)
    | loc, Call x -> id (this#call loc) x expr (fun x -> loc, Call x)
    | loc, Class x -> id this#class_ x expr (fun x -> loc, Class x)
    | loc, Comprehension x -> id this#comprehension x expr (fun x -> loc, Comprehension x)
    | loc, Conditional x -> id this#conditional x expr (fun x -> loc, Conditional x)
    | loc, Function x -> id this#function_ x expr (fun x -> loc, Function x)
    | loc, Generator x -> id this#generator x expr (fun x -> loc, Generator x)
    | loc, Identifier x -> id this#identifier x expr (fun x -> loc, Identifier x)
    | loc, Import x -> id (this#import loc) x expr (fun x -> loc, Import x)
    | loc, JSXElement x -> id this#jsx_element x expr (fun x -> loc, JSXElement x)
    | loc, JSXFragment x -> id this#jsx_fragment x expr (fun x -> loc, JSXFragment x)
    | loc, Literal x -> id this#literal x expr (fun x -> loc, Literal x)
    | loc, Logical x -> id this#logical x expr (fun x -> loc, Logical x)
    | loc, Member x -> id this#member x expr (fun x -> loc, Member x)
    | loc, MetaProperty x -> id this#meta_property x expr (fun x -> loc, MetaProperty x)
    | loc, New x -> id this#new_ x expr (fun x -> loc, New x)
    | loc, Object x -> id this#object_ x expr (fun x -> loc, Object x)
    | loc, OptionalCall x -> id (this#optional_call loc) x expr (fun x -> loc, OptionalCall x)
    | loc, OptionalMember x -> id this#optional_member x expr (fun x -> loc, OptionalMember x)
    | loc, Sequence x -> id this#sequence x expr (fun x -> loc, Sequence x)
    | loc, TaggedTemplate x -> id this#tagged_template x expr (fun x -> loc, TaggedTemplate x)
    | loc, TemplateLiteral x -> id this#template_literal x expr (fun x -> loc, TemplateLiteral x)
    | loc, TypeCast x -> id this#type_cast x expr (fun x -> loc, TypeCast x)
    | loc, Unary x -> id this#unary_expression x expr (fun x -> loc, Unary x)
    | loc, Update x -> id this#update_expression x expr (fun x -> loc, Update x)
    | loc, Yield x -> id this#yield x expr (fun x -> loc, Yield x)

  method array (expr: (Loc.t, Loc.t) Flow_ast.Expression.Array.t) =
    let open Flow_ast.Expression in
    let { Array.elements } = expr in
    let elements' = ListUtils.ident_map (map_opt this#expression_or_spread) elements in
    if elements == elements' then expr
    else { Array.elements = elements' }

  method arrow_function (expr: (Loc.t, Loc.t) Flow_ast.Function.t) =
    this#function_ expr

  method assignment (expr: (Loc.t, Loc.t) Flow_ast.Expression.Assignment.t) =
    let open Flow_ast.Expression.Assignment in
    let { operator = _; left; right } = expr in
    let left' = this#assignment_pattern left in
    let right' = this#expression right in
    if left == left' && right == right' then expr
    else { expr with left = left'; right = right' }

  method binary (expr: (Loc.t, Loc.t) Flow_ast.Expression.Binary.t) =
    let open Flow_ast.Expression.Binary in
    let { operator = _; left; right } = expr in
    let left' = this#expression left in
    let right' = this#expression right in
    if left == left' && right == right' then expr
    else { expr with left = left'; right = right' }

  method block (stmt: (Loc.t, Loc.t) Flow_ast.Statement.Block.t) =
    let open Flow_ast.Statement.Block in
    let { body } = stmt in
    let body' = this#statement_list body in
    if body == body' then stmt else { body = body' }

  method break (break: Loc.t Flow_ast.Statement.Break.t) =
    let open Flow_ast.Statement.Break in
    let { label } = break in
    let label' = map_opt this#label_identifier label in
    if label == label' then break else { label = label' }

  method call _loc (expr: (Loc.t, Loc.t) Flow_ast.Expression.Call.t) =
    let open Flow_ast.Expression.Call in
    let { callee; targs; arguments } = expr in
    let callee' = this#expression callee in
    let targs' = map_opt this#type_parameter_instantiation targs in
    let arguments' = ListUtils.ident_map this#expression_or_spread arguments in
    if callee == callee' && targs == targs' && arguments == arguments' then expr
    else { callee = callee'; targs = targs'; arguments = arguments' }

  method optional_call loc (expr: (Loc.t, Loc.t) Flow_ast.Expression.OptionalCall.t) =
    let open Flow_ast.Expression.OptionalCall in
    let { call; optional = _ } = expr in
    let call' = this#call loc call in
    if call == call' then expr
    else { expr with call = call' }

  method catch_clause (clause: (Loc.t, Loc.t) Flow_ast.Statement.Try.CatchClause.t') =
    let open Flow_ast.Statement.Try.CatchClause in
    let { param; body } = clause in

    let param' = map_opt this#catch_clause_pattern param in
    let body' = map_loc this#block body in
    if param == param' && body == body' then clause
    else { param = param'; body = body' }

  method class_ (cls: (Loc.t, Loc.t) Flow_ast.Class.t) =
    let open Flow_ast.Class in
    let {
      id; body; tparams = _;
      extends;
      implements = _; classDecorators = _;
    } = cls in
    let id' = map_opt this#class_identifier id in
    let body' = this#class_body body in
    let extends' = map_opt (map_loc this#class_extends) extends in
    if id == id' && body == body' && extends == extends' then cls
    else { cls with id = id'; body = body'; extends = extends' }

  method class_extends (extends: (Loc.t, Loc.t) Flow_ast.Class.Extends.t') =
    let open Flow_ast.Class.Extends in
    let { expr; targs } = extends in
    let expr' = this#expression expr in
    let targs' = map_opt this#type_parameter_instantiation targs in
    if expr == expr' && targs == targs' then extends
    else { expr = expr'; targs = targs' }

  method class_identifier (ident: Loc.t Flow_ast.Identifier.t) =
    this#pattern_identifier ~kind:Flow_ast.Statement.VariableDeclaration.Let ident

  method class_body (cls_body: (Loc.t, Loc.t) Flow_ast.Class.Body.t) =
    let open Flow_ast.Class.Body in
    let loc, { body } = cls_body in
    let body' = ListUtils.ident_map this#class_element body in
    if body == body' then cls_body
    else loc, { body = body' }

  method class_element (elem: (Loc.t, Loc.t) Flow_ast.Class.Body.element) =
    let open Flow_ast.Class.Body in
    match elem with
    | Method (loc, meth) -> id this#class_method meth elem (fun meth -> Method (loc, meth))
    | Property (loc, prop) -> id this#class_property prop elem (fun prop -> Property (loc, prop))
    | PrivateField (loc, field) -> id this#class_private_field field elem
      (fun field -> PrivateField (loc, field))

  method class_method (meth: (Loc.t, Loc.t) Flow_ast.Class.Method.t') =
    let open Flow_ast.Class.Method in
    let { kind = _; key; value; static = _; decorators = _; } = meth in
    let key' = this#object_key key in
    let value' = map_loc this#function_ value in
    if key == key' && value == value' then meth
    else { meth with key = key'; value = value' }

  method class_property (prop: (Loc.t, Loc.t) Flow_ast.Class.Property.t') =
    let open Flow_ast.Class.Property in
    let { key; value; annot; static = _; variance = _; } = prop in
    let key' = this#object_key key in
    let value' = map_opt this#expression value in
    let annot' = map_opt this#type_annotation annot in
    if key == key' && value == value' && annot' == annot then prop
    else { prop with key = key'; value = value'; annot = annot' }

  method class_private_field (prop: (Loc.t, Loc.t) Flow_ast.Class.PrivateField.t') =
    let open Flow_ast.Class.PrivateField in
    let { key; value; annot; static = _; variance = _; } = prop in
    let key' = this#private_name key in
    let value' = map_opt this#expression value in
    let annot' = map_opt this#type_annotation annot in
    if key == key' && value == value' && annot' == annot then prop
    else { prop with key = key'; value = value'; annot = annot' }

  (* TODO *)
  method comprehension (expr: (Loc.t, Loc.t) Flow_ast.Expression.Comprehension.t) = expr

  method conditional (expr: (Loc.t, Loc.t) Flow_ast.Expression.Conditional.t) =
    let open Flow_ast.Expression.Conditional in
    let { test; consequent; alternate } = expr in
    let test' = this#predicate_expression test in
    let consequent' = this#expression consequent in
    let alternate' = this#expression alternate in
    if test == test' && consequent == consequent' && alternate == alternate'
    then expr
    else { test = test'; consequent = consequent'; alternate = alternate' }

  method continue (cont: Loc.t Flow_ast.Statement.Continue.t) =
    let open Flow_ast.Statement.Continue in
    let { label } = cont in
    let label' = map_opt this#label_identifier label in
    if label == label' then cont else { label = label' }

  method debugger () =
    ()

  method declare_class (decl: (Loc.t, Loc.t) Flow_ast.Statement.DeclareClass.t) =
    let open Flow_ast.Statement.DeclareClass in
    let { id = ident; tparams; body; extends; mixins; implements } = decl in
    let id' = this#class_identifier ident in
    let tparams' = map_opt this#type_parameter_declaration tparams in
    let body' = map_loc this#object_type body in
    let extends' = map_opt (map_loc this#generic_type) extends in
    let mixins' = ListUtils.ident_map (map_loc this#generic_type) mixins in
    if id' == ident && tparams' == tparams && body' == body && extends' == extends
      && mixins' == mixins then decl
    else { id = id'; tparams = tparams'; body = body'; extends = extends';
           mixins = mixins'; implements }

  method declare_export_declaration _loc (decl: (Loc.t, Loc.t) Flow_ast.Statement.DeclareExportDeclaration.t) =
    let open Flow_ast.Statement.DeclareExportDeclaration in
    let { default; source; specifiers; declaration } = decl in
    let specifiers' = map_opt this#export_named_specifier specifiers in
    let declaration' = map_opt this#declare_export_declaration_decl declaration in
    if specifiers == specifiers' && declaration == declaration' then decl
    else { default; source; specifiers = specifiers'; declaration = declaration' }

  (* TODO(T22777134): Implement this when the mapper supports OpaqueType. *)
  method declare_export_declaration_decl (decl: (Loc.t, Loc.t) Flow_ast.Statement.DeclareExportDeclaration.declaration) =
    decl

  method declare_function (decl: (Loc.t, Loc.t) Flow_ast.Statement.DeclareFunction.t) =
    let open Flow_ast.Statement.DeclareFunction in
    let { id = ident; annot; predicate } = decl in
    let id' = this#function_identifier ident in
    let annot' = this#type_annotation annot in
    (* TODO: walk predicate *)
    if id' == ident && annot' == annot then decl
    else { id = id'; annot = annot'; predicate }

  method declare_interface (decl: (Loc.t, Loc.t) Flow_ast.Statement.Interface.t) =
    this#interface decl

  method declare_module _loc (m: (Loc.t, Loc.t) Flow_ast.Statement.DeclareModule.t) =
    let open Flow_ast.Statement.DeclareModule in
    let { id; body; kind } = m in
    let body' = map_loc this#block body in
    if body' == body then m
    else { id; body = body'; kind }

  (* TODO *)
  method declare_module_exports _loc (annot: (Loc.t, Loc.t) Flow_ast.Type.annotation) =
    annot

  method declare_type_alias (decl: (Loc.t, Loc.t) Flow_ast.Statement.TypeAlias.t) =
    this#type_alias decl

  method declare_variable (decl: (Loc.t, Loc.t) Flow_ast.Statement.DeclareVariable.t) =
    let open Flow_ast.Statement.DeclareVariable in
    let { id = ident; annot } = decl in
    let id' = this#pattern_identifier ~kind:Flow_ast.Statement.VariableDeclaration.Var ident in
    let annot' = map_opt this#type_annotation annot in
    if id' == ident && annot' == annot then decl
    else { id = id'; annot = annot' }

  method do_while (stuff: (Loc.t, Loc.t) Flow_ast.Statement.DoWhile.t) =
    let open Flow_ast.Statement.DoWhile in
    let { body; test } = stuff in
    let body' = this#statement body in
    let test' = this#predicate_expression test in
    if body == body' && test == test' then stuff
    else { body = body'; test = test' }

  method empty () =
    ()

  method export_default_declaration _loc (decl: (Loc.t, Loc.t) Flow_ast.Statement.ExportDefaultDeclaration.t) =
    let open Flow_ast.Statement.ExportDefaultDeclaration in
    let { default; declaration } = decl in
    let declaration' = this#export_default_declaration_decl declaration in
    if declaration' = declaration then decl
    else { default; declaration = declaration' }

  method export_default_declaration_decl (decl: (Loc.t, Loc.t) Flow_ast.Statement.ExportDefaultDeclaration.declaration) =
    let open Flow_ast.Statement.ExportDefaultDeclaration in
    match decl with
    | Declaration stmt -> id this#statement stmt decl (fun stmt -> Declaration stmt)
    | Expression expr -> id this#expression expr decl (fun expr -> Expression expr)

  method export_named_declaration _loc (decl: (Loc.t, Loc.t) Flow_ast.Statement.ExportNamedDeclaration.t) =
    let open Flow_ast.Statement.ExportNamedDeclaration in
    let { exportKind; source; specifiers; declaration } = decl in
    let specifiers' = map_opt this#export_named_specifier specifiers in
    let declaration' = map_opt this#statement declaration in
    if specifiers == specifiers' && declaration == declaration' then decl
    else { exportKind; source; specifiers = specifiers'; declaration = declaration' }

  (* TODO *)
  method export_named_specifier (spec: Loc.t Flow_ast.Statement.ExportNamedDeclaration.specifier) =
    spec

  method expression_statement (stmt: (Loc.t, Loc.t) Flow_ast.Statement.Expression.t) =
    let open Flow_ast.Statement.Expression in
    let { expression = expr; directive = _ } = stmt in
    id this#expression expr stmt (fun expression -> { stmt with expression })

  method expression_or_spread expr_or_spread =
    let open Flow_ast.Expression in
    match expr_or_spread with
    | Expression expr ->
      id this#expression expr expr_or_spread (fun expr -> Expression expr)
    | Spread spread ->
      id this#spread_element spread expr_or_spread (fun spread -> Spread spread)

  method for_in_statement (stmt: (Loc.t, Loc.t) Flow_ast.Statement.ForIn.t) =
    let open Flow_ast.Statement.ForIn in
    let { left; right; body; each } = stmt in
    let left' = this#for_in_statement_lhs left in
    let right' = this#expression right in
    let body' = this#statement body in
    if left == left' && right == right' && body == body' then stmt
    else { left = left'; right = right'; body = body'; each }

  method for_in_statement_lhs (left: (Loc.t, Loc.t) Flow_ast.Statement.ForIn.left) =
    let open Flow_ast.Statement.ForIn in
    match left with
    | LeftDeclaration (loc, decl) ->
      id this#variable_declaration decl left (fun decl -> LeftDeclaration (loc, decl))
    | LeftPattern patt ->
      id this#for_in_assignment_pattern patt left (fun patt -> LeftPattern patt)

  method for_of_statement (stuff: (Loc.t, Loc.t) Flow_ast.Statement.ForOf.t) =
    let open Flow_ast.Statement.ForOf in
    let { left; right; body; async } = stuff in
    let left' = this#for_of_statement_lhs left in
    let right' = this#expression right in
    let body' = this#statement body in
    if left == left' && right == right' && body == body' then stuff
    else { left = left'; right = right'; body = body'; async }

  method for_of_statement_lhs (left: (Loc.t, Loc.t) Flow_ast.Statement.ForOf.left) =
    let open Flow_ast.Statement.ForOf in
    match left with
    | LeftDeclaration (loc, decl) ->
      id this#variable_declaration decl left (fun decl -> LeftDeclaration (loc, decl))
    | LeftPattern patt ->
      id this#for_of_assignment_pattern patt left (fun patt -> LeftPattern patt)

  method for_statement (stmt: (Loc.t, Loc.t) Flow_ast.Statement.For.t) =
    let open Flow_ast.Statement.For in
    let { init; test; update; body } = stmt in
    let init' = map_opt this#for_statement_init init in
    let test' = map_opt this#predicate_expression test in
    let update' = map_opt this#expression update in
    let body' = this#statement body in
    if init == init' &&
       test == test' &&
       update == update' &&
       body == body'
      then stmt
      else { init = init'; test = test'; update = update'; body = body' }

  method for_statement_init (init: (Loc.t, Loc.t) Flow_ast.Statement.For.init) =
    let open Flow_ast.Statement.For in
    match init with
    | InitDeclaration (loc, decl) ->
      id this#variable_declaration decl init
        (fun decl -> InitDeclaration (loc, decl))
    | InitExpression expr ->
      id this#expression expr init (fun expr -> InitExpression expr)

  method function_param_type (fpt: (Loc.t, Loc.t) Flow_ast.Type.Function.Param.t) =
    let open Flow_ast.Type.Function.Param in
    let loc, { annot; name; optional; } = fpt in
    let annot' = this#type_ annot in
    if annot' == annot then fpt
    else loc, { annot = annot'; name; optional }

  method function_rest_param_type (frpt: (Loc.t, Loc.t) Flow_ast.Type.Function.RestParam.t) =
    let open Flow_ast.Type.Function.RestParam in
    let loc, { argument } = frpt in
    let argument' = this#function_param_type argument in
    if argument' == argument then frpt
    else loc, { argument = argument' }

  method function_type (ft: (Loc.t, Loc.t) Flow_ast.Type.Function.t) =
    let open Flow_ast.Type.Function in
    let {
      params = (params_loc, { Params.params = ps; rest = rpo });
      return;
      tparams;
    } = ft in
    let ps' = ListUtils.ident_map this#function_param_type ps in
    let rpo' = map_opt this#function_rest_param_type rpo in
    let return' = this#type_ return in
    if ps' == ps && rpo' == rpo && return' == return then ft
    else {
      params = (params_loc, { Params.params = ps'; rest = rpo' });
      return = return';
      tparams
    }

  method label_identifier (ident: Loc.t Flow_ast.Identifier.t) =
    this#identifier ident

  method object_property_value_type (opvt: (Loc.t, Loc.t) Flow_ast.Type.Object.Property.value) =
    let open Flow_ast.Type.Object.Property in
    match opvt with
    | Init t -> id this#type_ t opvt (fun t -> Init t)
    | Get (loc, ft) -> id this#function_type ft opvt (fun ft -> Get (loc, ft))
    | Set (loc, ft) -> id this#function_type ft opvt (fun ft -> Set (loc, ft))

  method object_property_type (opt: (Loc.t, Loc.t) Flow_ast.Type.Object.Property.t) =
    let open Flow_ast.Type.Object.Property in
    let loc, { key; value; optional; static; proto; _method; variance; } = opt in
    let value' = this#object_property_value_type value in
    if value' == value then opt
    else loc, { key; value = value'; optional; static; proto; _method; variance }

  method object_spread_property_type (opt: (Loc.t, Loc.t) Flow_ast.Type.Object.SpreadProperty.t) =
    let open Flow_ast.Type.Object.SpreadProperty in
    let loc, { argument; } = opt in
    let argument' = this#type_ argument in
    if argument' == argument then opt
    else loc, { argument = argument'; }

  method object_indexer_property_type (opt: (Loc.t, Loc.t) Flow_ast.Type.Object.Indexer.t) =
    let open Flow_ast.Type.Object.Indexer in
    let loc, { id; key; value; static; variance; } = opt in
    let key' = this#type_ key in
    let value' = this#type_ value in
    if key' == key && value' == value then opt
    else loc, { id; key = key'; value = value'; static; variance; }

  method object_type (ot: (Loc.t, Loc.t) Flow_ast.Type.Object.t) =
    let open Flow_ast.Type.Object in
    let { properties ; exact; } = ot in
    let properties' = ListUtils.ident_map (fun p -> match p with
      | Property p' -> id this#object_property_type p' p (fun p' -> Property p')
      | SpreadProperty p' -> id this#object_spread_property_type p' p (fun p' -> SpreadProperty p')
      | Indexer p' -> id this#object_indexer_property_type p' p (fun p' -> Indexer p')
      | CallProperty _
      | InternalSlot _ -> p (* TODO *)
    ) properties in
    if properties' == properties then ot
    else { properties = properties'; exact }

  method interface_type (i: (Loc.t, Loc.t) Flow_ast.Type.Interface.t) =
    let open Flow_ast.Type.Interface in
    let { extends; body } = i in
    let extends' = ListUtils.ident_map (map_loc this#generic_type) extends in
    let body' = map_loc this#object_type body in
    if extends' == extends && body' == body then i
    else { extends = extends'; body = body' }

  method generic_identifier_type (git: (Loc.t, Loc.t) Flow_ast.Type.Generic.Identifier.t) =
    let open Flow_ast.Type.Generic.Identifier in
    match git with
    | Unqualified i -> id this#identifier i git (fun i -> Unqualified i)
    | _ -> git (* TODO *)

  method type_parameter_instantiation (pi: (Loc.t, Loc.t) Flow_ast.Type.ParameterInstantiation.t) =
    let loc, targs = pi in
    let targs' = ListUtils.ident_map this#type_ targs in
    if targs' == targs then pi
    else loc, targs'

  method type_parameter_declaration (pd: (Loc.t, Loc.t) Flow_ast.Type.ParameterDeclaration.t) =
    let loc, type_params = pd in
    let type_params' = ListUtils.ident_map this#type_parameter_declaration_type_param type_params in
    if type_params' == type_params then pd
    else loc, type_params'

  method type_parameter_declaration_type_param (type_param: (Loc.t, Loc.t) Flow_ast.Type.ParameterDeclaration.TypeParam.t) =
    let open Flow_ast.Type.ParameterDeclaration.TypeParam in
    let loc, { name; bound; variance; default; } = type_param in
    let bound' = map_opt this#type_annotation bound in
    let default' = map_opt this#type_ default in
    if bound' == bound && default' == default then type_param
    else loc, { name; bound = bound'; variance; default = default'; }

  method generic_type (gt: (Loc.t, Loc.t) Flow_ast.Type.Generic.t) =
    let open Flow_ast.Type.Generic in
    let { id; targs; } = gt in
    let id' = this#generic_identifier_type id in
    let targs' = map_opt this#type_parameter_instantiation targs in
    if id' == id && targs' == targs then gt
    else { id = id'; targs = targs' }

  method type_ (t: (Loc.t, Loc.t) Flow_ast.Type.t) =
    let open Flow_ast.Type in
    match t with
    | _, Any
    | _, Mixed
    | _, Empty
    | _, Void
    | _, Null
    | _, Number
    | _, String
    | _, Boolean
    | _, StringLiteral _
    | _, NumberLiteral _
    | _, BooleanLiteral _
    | _, Exists
      -> t
    | loc, Nullable t' -> id this#type_ t' t (fun t' -> loc, Nullable t')
    | loc, Array t' -> id this#type_ t' t (fun t' -> loc, Array t')
    | loc, Typeof t' -> id this#type_ t' t (fun t' -> loc, Typeof t')
    | loc, Function ft -> id this#function_type ft t (fun ft -> loc, Function ft)
    | loc, Object ot -> id this#object_type ot t (fun ot -> loc, Object ot)
    | loc, Interface i -> id this#interface_type i t (fun i -> loc, Interface i)
    | loc, Generic gt -> id this#generic_type gt t (fun gt -> loc, Generic gt)
    | loc, Union (t0, t1, ts) ->
      let t0' = this#type_ t0 in
      let t1' = this#type_ t1 in
      let ts' = ListUtils.ident_map this#type_ ts in
      if t0' == t0 && t1' == t1 && ts' == ts then t
      else loc, Union (t0', t1', ts')
    | loc, Intersection (t0, t1, ts) ->
      let t0' = this#type_ t0 in
      let t1' = this#type_ t1 in
      let ts' = ListUtils.ident_map this#type_ ts in
      if t0' == t0 && t1' == t1 && ts' == ts then t
      else loc, Intersection (t0', t1', ts')
    | loc, Tuple ts ->
      let ts' = ListUtils.ident_map this#type_ ts in
      if ts' == ts then t
      else loc, Tuple ts'

  method type_annotation (annot: (Loc.t, Loc.t) Flow_ast.Type.annotation) =
    map_loc this#type_ annot

  method function_ (expr: (Loc.t, Loc.t) Flow_ast.Function.t) =
    let open Flow_ast.Function in
    let {
      id = ident; params; body; async; generator; expression;
      predicate; return; tparams;
    } = expr in
    let ident' = map_opt this#function_identifier ident in
    let params' = this#function_params params in
    let return' = map_opt this#type_annotation return in
    let body' = this#function_body_any body in
    (* TODO: walk predicate *)
    let tparams' = map_opt this#type_parameter_declaration tparams in
    if ident == ident' && params == params' && body == body' && return == return'
      && tparams == tparams' then expr
    else {
      id = ident'; params = params'; return = return'; body = body';
      async; generator; expression; predicate; tparams = tparams';
    }

  method function_params (params: (Loc.t, Loc.t) Flow_ast.Function.Params.t) =
    let open Flow_ast.Function in
    let (loc, { Params.params = params_list; rest }) = params in
    let params_list' = this#function_param_patterns params_list in
    let rest' = map_opt this#function_rest_element rest in
    if params_list == params_list' && rest == rest' then params
    else (loc, { Params.params = params_list'; rest = rest' })

  method function_param_patterns (params_list: (Loc.t, Loc.t) Flow_ast.Pattern.t list) =
    ListUtils.ident_map this#function_param_pattern params_list

  method function_body_any (body: (Loc.t, Loc.t) Flow_ast.Function.body) =
    match body with
      | Flow_ast.Function.BodyBlock (loc, block) ->
        id this#function_body block body (fun block -> Flow_ast.Function.BodyBlock (loc, block))
      | Flow_ast.Function.BodyExpression expr ->
        id this#expression expr body (fun expr -> Flow_ast.Function.BodyExpression expr)

  method function_body (block: (Loc.t, Loc.t) Flow_ast.Statement.Block.t) =
    this#block block

  method function_identifier (ident: Loc.t Flow_ast.Identifier.t) =
    this#pattern_identifier ~kind:Flow_ast.Statement.VariableDeclaration.Var ident

  method function_declaration (stmt: (Loc.t, Loc.t) Flow_ast.Function.t) =
    this#function_ stmt

  (* TODO *)
  method generator (expr: (Loc.t, Loc.t) Flow_ast.Expression.Generator.t) = expr

  method identifier (expr: Loc.t Flow_ast.Identifier.t) = expr

  method interface (interface: (Loc.t, Loc.t) Flow_ast.Statement.Interface.t) =
    let open Flow_ast.Statement.Interface in
    let { id = ident; tparams; extends; body } = interface in
    let id' = this#class_identifier ident in
    let tparams' = map_opt this#type_parameter_declaration tparams in
    let extends' = ListUtils.ident_map (map_loc this#generic_type) extends in
    let body' = map_loc this#object_type body in
    if id' == ident && tparams' == tparams && extends' == extends && body' == body
    then interface
    else { id = id'; tparams = tparams'; extends = extends'; body = body' }

  method interface_declaration (decl: (Loc.t, Loc.t) Flow_ast.Statement.Interface.t) =
    this#interface decl

  method private_name (expr: Loc.t Flow_ast.PrivateName.t) = expr

  method import _loc (expr: (Loc.t, Loc.t) Flow_ast.Expression.t) = expr

  method if_consequent_statement ~has_else (stmt: (Loc.t, Loc.t) Flow_ast.Statement.t) =
    ignore has_else;
    this#statement stmt

  method if_statement (stmt: (Loc.t, Loc.t) Flow_ast.Statement.If.t) =
    let open Flow_ast.Statement.If in
    let { test; consequent; alternate } = stmt in
    let test' = this#predicate_expression test in
    let consequent' =
      this#if_consequent_statement ~has_else:(alternate <> None) consequent in
    let alternate' = map_opt this#statement alternate in
    if test == test' && consequent == consequent' && alternate == alternate'
    then stmt
    else { test = test'; consequent = consequent'; alternate = alternate' }

  method import_declaration _loc (decl: (Loc.t, Loc.t) Flow_ast.Statement.ImportDeclaration.t) =
    let open Flow_ast.Statement.ImportDeclaration in
    let { importKind; source; specifiers; default } = decl in
    match importKind with
    | ImportValue
    | ImportType ->
      let specifiers' = map_opt this#import_specifier specifiers in
      let default' = map_opt this#import_default_specifier default in
      if specifiers == specifiers' && default == default' then decl
      else { importKind; source; specifiers = specifiers'; default = default' }
    | ImportTypeof -> decl (* TODO *)

  method import_specifier (specifier: (Loc.t, Loc.t) Flow_ast.Statement.ImportDeclaration.specifier) =
    let open Flow_ast.Statement.ImportDeclaration in
    match specifier with
    | ImportNamedSpecifiers named_specifiers ->
      let named_specifiers' = ListUtils.ident_map this#import_named_specifier named_specifiers in
      if named_specifiers == named_specifiers' then specifier
      else ImportNamedSpecifiers named_specifiers'
    | ImportNamespaceSpecifier (loc, ident) ->
      id this#import_namespace_specifier ident specifier
        (fun ident -> ImportNamespaceSpecifier (loc, ident))

  method import_named_specifier (specifier: Loc.t Flow_ast.Statement.ImportDeclaration.named_specifier) =
    let open Flow_ast.Statement.ImportDeclaration in
    let { kind; local; remote } = specifier in
    begin match kind with
    | None ->
      let ident = match local with
        | None -> remote
        | Some ident -> ident
      in
      let local' = id (this#pattern_identifier ~kind:Flow_ast.Statement.VariableDeclaration.Let)
        ident local (fun ident -> Some ident)
      in
      if local == local' then specifier
      else { kind; local = local'; remote }
    | Some _importKind -> specifier (* TODO *)
    end

  method import_default_specifier (id: Loc.t Flow_ast.Identifier.t) =
    this#pattern_identifier ~kind:Flow_ast.Statement.VariableDeclaration.Let id

  method import_namespace_specifier (id: Loc.t Flow_ast.Identifier.t) =
    this#pattern_identifier ~kind:Flow_ast.Statement.VariableDeclaration.Let id

  method jsx_element (expr: (Loc.t, Loc.t) Flow_ast.JSX.element) =
    let open Flow_ast.JSX in
    let { openingElement; closingElement; children } = expr in
    let openingElement' = this#jsx_opening_element openingElement in
    let closingElement' = map_opt this#jsx_closing_element closingElement in
    let children' = ListUtils.ident_map this#jsx_child children in
    if openingElement == openingElement' && closingElement == closingElement' && children == children' then expr
    else { openingElement = openingElement'; closingElement = closingElement'; children = children' }

  method jsx_fragment (expr: (Loc.t, Loc.t) Flow_ast.JSX.fragment) =
    let open Flow_ast.JSX in
    let { frag_children; _ } = expr in
    let children' = ListUtils.ident_map this#jsx_child frag_children in
    { expr with frag_children = children' }

  method jsx_opening_element (elem: (Loc.t, Loc.t) Flow_ast.JSX.Opening.t) =
    let open Flow_ast.JSX.Opening in
    let loc, { name; selfClosing; attributes } = elem in
    let name' = this#jsx_name name in
    let attributes' = ListUtils.ident_map this#jsx_opening_attribute attributes in
    if name == name' && attributes == attributes' then elem
    else loc, { name; selfClosing; attributes = attributes' }

  method jsx_closing_element (elem: Loc.t Flow_ast.JSX.Closing.t) =
    let open Flow_ast.JSX.Closing in
    let loc, {name} = elem in
    let name' = this#jsx_name name in
    if name == name' then elem else loc, {name=name'}

  method jsx_opening_attribute (jsx_attr: (Loc.t, Loc.t) Flow_ast.JSX.Opening.attribute) =
    let open Flow_ast.JSX.Opening in
    match jsx_attr with
    | Attribute attr ->
      id this#jsx_attribute attr jsx_attr (fun attr -> Attribute attr)
    | SpreadAttribute (loc, attr) ->
      id this#jsx_spread_attribute attr jsx_attr (fun attr -> SpreadAttribute (loc, attr))

  method jsx_spread_attribute (attr: (Loc.t, Loc.t) Flow_ast.JSX.SpreadAttribute.t') =
    let open Flow_ast.JSX.SpreadAttribute in
    let { argument } = attr in
    id this#expression argument attr (fun argument -> { argument })

  method jsx_attribute (attr: (Loc.t, Loc.t) Flow_ast.JSX.Attribute.t) =
    let open Flow_ast.JSX.Attribute in
    let loc, { name; value } = attr in
    let value' = map_opt this#jsx_attribute_value value in
    if value == value' then attr
    else loc, { name; value = value' }

  method jsx_attribute_value (value: (Loc.t, Loc.t) Flow_ast.JSX.Attribute.value) =
    let open Flow_ast.JSX.Attribute in
    match value with
    | Literal _ -> value
    | ExpressionContainer (expr_loc, expr) ->
      id this#jsx_expression expr value (fun expr -> ExpressionContainer (expr_loc, expr))

  method jsx_child (child: (Loc.t, Loc.t) Flow_ast.JSX.child) =
    let open Flow_ast.JSX in
    let loc, child' = child in
    match child' with
    | Element elem ->
      id this#jsx_element elem child (fun elem -> loc, Element elem)
    | Fragment frag ->
      id this#jsx_fragment frag child (fun frag -> loc, Fragment frag)
    | ExpressionContainer expr ->
      id this#jsx_expression expr child (fun expr -> loc, ExpressionContainer expr)
    | SpreadChild expr ->
      id this#expression expr child (fun expr -> loc, SpreadChild expr)
    | Text _ -> child

  method jsx_expression (jsx_expr: (Loc.t, Loc.t) Flow_ast.JSX.ExpressionContainer.t) =
    let open Flow_ast.JSX.ExpressionContainer in
    let { expression } = jsx_expr in
    match expression with
    | Expression expr ->
      id this#expression expr jsx_expr (fun expr -> { expression = Expression expr})
    | EmptyExpression _ -> jsx_expr

  method jsx_name (name: Loc.t Flow_ast.JSX.name) =
    let open Flow_ast.JSX in
    let name' = match name with
      | Identifier id -> Identifier (this#jsx_identifier id)
      | NamespacedName namespaced_name ->
          NamespacedName (this#jsx_namespaced_name namespaced_name)
      | MemberExpression member_exp ->
          MemberExpression (this#jsx_member_expression member_exp)
    in
    (* structural equality since it's easier than checking equality in each branch of the match
     * above *)
    if name = name' then name else name'

  method jsx_namespaced_name (namespaced_name: Loc.t Flow_ast.JSX.NamespacedName.t) =
    let open Flow_ast.JSX in
    let open NamespacedName in
    let loc, {namespace; name} = namespaced_name in
    let namespace' = this#jsx_identifier namespace in
    let name' = this#jsx_identifier name in
    if namespace == namespace' && name == name' then
      namespaced_name
    else
      loc, {namespace=namespace'; name=name'}

  method jsx_member_expression (member_exp: Loc.t Flow_ast.JSX.MemberExpression.t) =
    let open Flow_ast.JSX in
    let loc, {MemberExpression._object; MemberExpression.property} = member_exp in
    let _object' = match _object with
      | MemberExpression.Identifier id ->
          let id' = this#jsx_identifier id in
          if id' == id then _object else MemberExpression.Identifier id'
      | MemberExpression.MemberExpression nested_exp ->
          let nested_exp' = this#jsx_member_expression nested_exp in
          if nested_exp' == nested_exp then
            _object
          else
            MemberExpression.MemberExpression nested_exp'
    in
    let property' = this#jsx_identifier property in
    if _object == _object' && property == property' then
      member_exp
    else
      loc, MemberExpression.({_object=_object'; property=property'})

  method jsx_identifier (id: Loc.t Flow_ast.JSX.Identifier.t) = id

  method labeled_statement (stmt: (Loc.t, Loc.t) Flow_ast.Statement.Labeled.t) =
    let open Flow_ast.Statement.Labeled in
    let { label; body } = stmt in
    let label' = this#label_identifier label in
    let body' = this#statement body in
    if label == label' && body == body' then stmt
    else { label = label'; body = body' }

  method literal (expr: Flow_ast.Literal.t) = expr

  method logical (expr: (Loc.t, Loc.t) Flow_ast.Expression.Logical.t) =
    let open Flow_ast.Expression.Logical in
    let { operator = _; left; right } = expr in
    let left' = this#expression left in
    let right' = this#expression right in
    if left == left' && right == right' then expr
    else { expr with left = left'; right = right' }

  method member (expr: (Loc.t, Loc.t) Flow_ast.Expression.Member.t) =
    let open Flow_ast.Expression.Member in
    let { _object; property; computed = _ } = expr in
    let _object' = this#expression _object in
    let property' = this#member_property property in
    if _object == _object' && property == property' then expr
    else { expr with _object = _object'; property = property' }

  method optional_member (expr: (Loc.t, Loc.t) Flow_ast.Expression.OptionalMember.t) =
    let open Flow_ast.Expression.OptionalMember in
    let { member; optional = _ } = expr in
    let member' = this#member member in
    if member == member' then expr
    else { expr with member = member' }

  method member_property (expr: (Loc.t, Loc.t) Flow_ast.Expression.Member.property) =
    let open Flow_ast.Expression.Member in
    match expr with
    | PropertyIdentifier ident ->
      id this#member_property_identifier ident expr
        (fun ident -> PropertyIdentifier ident)
    | PropertyPrivateName ident ->
      id this#member_private_name ident expr
        (fun ident -> PropertyPrivateName ident)
    | PropertyExpression e ->
      id this#member_property_expression e expr (fun e -> PropertyExpression e)

  method member_property_identifier (ident: Loc.t Flow_ast.Identifier.t) =
    this#identifier ident

  method member_private_name (name: Loc.t Flow_ast.PrivateName.t) =
    this#private_name name

  method member_property_expression (expr: (Loc.t, Loc.t) Flow_ast.Expression.t) =
    this#expression expr

  (* TODO *)
  method meta_property (expr: Loc.t Flow_ast.Expression.MetaProperty.t) = expr

  method new_ (expr: (Loc.t, Loc.t) Flow_ast.Expression.New.t) =
    let open Flow_ast.Expression.New in
    let { callee; targs; arguments } = expr in
    let callee' = this#expression callee in
    let targs' = map_opt this#type_parameter_instantiation targs in
    let arguments' = ListUtils.ident_map this#expression_or_spread arguments in
    if callee == callee' && targs == targs' && arguments == arguments' then expr
    else { callee = callee'; targs = targs'; arguments = arguments' }

  method object_ (expr: (Loc.t, Loc.t) Flow_ast.Expression.Object.t) =
    let open Flow_ast.Expression.Object in
    let { properties } = expr in
    let properties' = ListUtils.ident_map (fun prop ->
      match prop with
      | Property p ->
        let p' = this#object_property p in
        if p == p' then prop else Property p'
      | SpreadProperty s ->
        let s' = this#spread_property s in
        if s == s' then prop else SpreadProperty s'
    ) properties in
    if properties == properties' then expr
    else { properties = properties' }

  method object_property (prop: (Loc.t, Loc.t) Flow_ast.Expression.Object.Property.t) =
    let open Flow_ast.Expression.Object.Property in
    match prop with
    | loc, Init { key; value; shorthand } ->
      let key' = this#object_key key in
      let value' = this#expression value in
      if key == key' && value == value' then prop
      else (loc, Init { key = key'; value = value'; shorthand })

    | loc, Method { key; value = (fn_loc, fn) } ->
      let key' = this#object_key key in
      let fn' = this#function_ fn in
      if key == key' && fn == fn' then prop
      else (loc, Method { key = key'; value = (fn_loc, fn') })

    | loc, Get { key; value = (fn_loc, fn) } ->
      let key' = this#object_key key in
      let fn' = this#function_ fn in
      if key == key' && fn == fn' then prop
      else (loc, Get { key = key'; value = (fn_loc, fn') })

    | loc, Set { key; value = (fn_loc, fn) } ->
      let key' = this#object_key key in
      let fn' = this#function_ fn in
      if key == key' && fn == fn' then prop
      else (loc, Set { key = key'; value = (fn_loc, fn') })

  method object_key (key: (Loc.t, Loc.t) Flow_ast.Expression.Object.Property.key) =
    let open Flow_ast.Expression.Object.Property in
    match key with
    | Literal (loc, lit) ->
      id this#literal lit key (fun lit -> Literal (loc, lit))
    | Identifier ident ->
      id this#object_key_identifier ident key (fun ident -> Identifier ident)
    | PrivateName ident ->
      id this#private_name ident key (fun ident -> PrivateName ident)
    | Computed expr ->
      id this#expression expr key (fun expr -> Computed expr)

  method object_key_identifier (ident: Loc.t Flow_ast.Identifier.t) =
    this#identifier ident

  method opaque_type (otype: (Loc.t, Loc.t) Flow_ast.Statement.OpaqueType.t) =
    let open Flow_ast.Statement.OpaqueType in
    let { id; tparams; impltype; supertype } = otype in
    let id' = this#identifier id in
    let tparams' = map_opt this#type_parameter_declaration tparams in
    let impltype' = map_opt this#type_ impltype in
    let supertype' = map_opt this#type_ supertype  in
    if id == id' &&
       impltype == impltype' &&
       tparams == tparams' &&
       impltype == impltype' &&
       supertype == supertype'
    then otype
    else {
      id = id';
      tparams = tparams';
      impltype = impltype';
      supertype = supertype'
    }

  method function_param_pattern (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#binding_pattern expr

  method variable_declarator_pattern ~kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#binding_pattern ~kind expr

  method catch_clause_pattern (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#binding_pattern ~kind:Flow_ast.Statement.VariableDeclaration.Let expr

  method for_in_assignment_pattern (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#assignment_pattern expr

  method for_of_assignment_pattern (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#assignment_pattern expr

  method binding_pattern ?(kind=Flow_ast.Statement.VariableDeclaration.Var) (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern ~kind expr

  method assignment_pattern (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern expr

  (* NOTE: Patterns are highly overloaded. A pattern can be a binding pattern,
     which has a kind (Var/Let/Const, with Var being the default for all pre-ES5
     bindings), or an assignment pattern, which has no kind. Subterms that are
     patterns inherit the kind (or lack thereof). *)
  method pattern ?kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    let open Flow_ast.Pattern in
    let (loc, patt) = expr in
    let patt' = match patt with
      | Object { Object.properties; annot } ->
        let properties' = ListUtils.ident_map (this#pattern_object_p ?kind) properties in
        let annot' = map_opt this#type_annotation annot in
        if properties' == properties && annot' == annot then patt
        else Object { Object.properties = properties'; annot = annot' }
      | Array { Array.elements; annot } ->
        let elements' = ListUtils.ident_map (map_opt (this#pattern_array_e ?kind)) elements in
        let annot' = map_opt this#type_annotation annot in
        if elements' == elements && annot' == annot then patt
        else Array { Array.elements = elements'; annot = annot' }
      | Assignment { Assignment.left; right } ->
        let left' = this#pattern_assignment_pattern ?kind left in
        let right' = this#expression right in
        if left == left' && right == right' then patt
        else Assignment { Assignment.left = left'; right = right' }
      | Identifier { Identifier.name; annot; optional } ->
        let name' = this#pattern_identifier ?kind name in
        let annot' = map_opt this#type_annotation annot in
        if name == name' && annot == annot' then patt
        else Identifier { Identifier.name = name'; annot = annot'; optional }
      | Expression e ->
        id this#pattern_expression e patt (fun e -> Expression e)
    in
    if patt == patt' then expr else (loc, patt')

  method pattern_identifier ?kind (ident: Loc.t Flow_ast.Identifier.t) =
    ignore kind;
    this#identifier ident

  method pattern_literal ?kind (expr: Flow_ast.Literal.t) =
    ignore kind;
    this#literal expr

  method pattern_object_p ?kind (p: (Loc.t, Loc.t) Flow_ast.Pattern.Object.property) =
    let open Flow_ast.Pattern.Object in
    match p with
    | Property (loc, prop) ->
      id (this#pattern_object_property ?kind) prop p (fun prop -> Property (loc, prop))
    | RestProperty (loc, prop) ->
      id (this#pattern_object_rest_property ?kind) prop p (fun prop -> RestProperty (loc, prop))

  method pattern_object_property ?kind (prop: (Loc.t, Loc.t) Flow_ast.Pattern.Object.Property.t') =
    let open Flow_ast.Pattern.Object.Property in
    let { key; pattern; shorthand = _ } = prop in
    let key' = this#pattern_object_property_key ?kind key in
    let pattern' = this#pattern_object_property_pattern ?kind pattern in
    if key' == key && pattern' == pattern then prop
    else { key = key'; pattern = pattern'; shorthand = false }

  method pattern_object_property_key ?kind (key: (Loc.t, Loc.t) Flow_ast.Pattern.Object.Property.key) =
    let open Flow_ast.Pattern.Object.Property in
    match key with
    | Literal (loc, lit) ->
      id (this#pattern_object_property_literal_key ?kind) lit key (fun lit' -> Literal (loc, lit'))
    | Identifier identifier ->
      id (this#pattern_object_property_identifier_key ?kind) identifier key (fun id' -> Identifier id')
    | Computed expr ->
      id (this#pattern_object_property_computed_key ?kind) expr key (fun expr' -> Computed expr')

  method pattern_object_property_literal_key ?kind (key: Flow_ast.Literal.t) =
    this#pattern_literal ?kind key

  method pattern_object_property_identifier_key ?kind (key: Loc.t Flow_ast.Identifier.t) =
    this#pattern_identifier ?kind key

  method pattern_object_property_computed_key ?kind (key: (Loc.t, Loc.t) Flow_ast.Expression.t) =
    ignore kind;
    this#pattern_expression key

  method pattern_object_rest_property ?kind (prop: (Loc.t, Loc.t) Flow_ast.Pattern.Object.RestProperty.t') =
    let open Flow_ast.Pattern.Object.RestProperty in
    let { argument } = prop in
    let argument' = this#pattern_object_rest_property_pattern ?kind argument in
    if argument' == argument then prop
    else { argument = argument' }

  method pattern_object_property_pattern ?kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern ?kind expr

  method pattern_object_rest_property_pattern ?kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern ?kind expr

  method pattern_array_e ?kind (e: (Loc.t, Loc.t) Flow_ast.Pattern.Array.element) =
    let open Flow_ast.Pattern.Array in
    match e with
    | Element elem ->
      id (this#pattern_array_element_pattern ?kind) elem e (fun elem -> Element elem)
    | RestElement (loc, elem) ->
      id (this#pattern_array_rest_element ?kind) elem e (fun elem -> RestElement (loc, elem))

  method pattern_array_element_pattern ?kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern ?kind expr

  method pattern_array_rest_element ?kind (elem: (Loc.t, Loc.t) Flow_ast.Pattern.Array.RestElement.t') =
    let open Flow_ast.Pattern.Array.RestElement in
    let { argument } = elem in
    let argument' = this#pattern_array_rest_element_pattern ?kind argument in
    if argument' == argument then elem
    else { argument = argument' }

  method pattern_array_rest_element_pattern ?kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern ?kind expr

  method pattern_assignment_pattern ?kind (expr: (Loc.t, Loc.t) Flow_ast.Pattern.t) =
    this#pattern ?kind expr

  method pattern_expression (expr: (Loc.t, Loc.t) Flow_ast.Expression.t) =
    this#expression expr

  method predicate_expression (expr: (Loc.t, Loc.t) Flow_ast.Expression.t) =
    this#expression expr

  (* TODO *)
  method function_rest_element (expr: (Loc.t, Loc.t) Flow_ast.Function.RestElement.t) = expr

  method return (stmt: (Loc.t, Loc.t) Flow_ast.Statement.Return.t) =
    let open Flow_ast.Statement.Return in
    let { argument } = stmt in
    let argument' = map_opt this#expression argument in
    if argument == argument' then stmt else { argument = argument' }

  method sequence (expr: (Loc.t, Loc.t) Flow_ast.Expression.Sequence.t) =
    let open Flow_ast.Expression.Sequence in
    let { expressions } = expr in
    let expressions' = ListUtils.ident_map this#expression expressions in
    if expressions == expressions' then expr else { expressions = expressions' }

  method toplevel_statement_list (stmts: (Loc.t, Loc.t) Flow_ast.Statement.t list) =
    this#statement_list stmts

  method statement_list (stmts: (Loc.t, Loc.t) Flow_ast.Statement.t list) =
    ListUtils.ident_map this#statement stmts

  method spread_element (expr: (Loc.t, Loc.t) Flow_ast.Expression.SpreadElement.t) =
    let open Flow_ast.Expression.SpreadElement in
    let loc, { argument } = expr in
    id this#expression argument expr (fun argument -> loc, { argument })

  method spread_property (expr: (Loc.t, Loc.t) Flow_ast.Expression.Object.SpreadProperty.t) =
    let open Flow_ast.Expression.Object.SpreadProperty in
    let (loc, { argument }) = expr in
    id this#expression argument expr (fun argument -> loc, { argument })

  method switch (switch: (Loc.t, Loc.t) Flow_ast.Statement.Switch.t) =
    let open Flow_ast.Statement.Switch in
    let { discriminant; cases } = switch in
    let discriminant' = this#expression discriminant in
    let cases' = ListUtils.ident_map (map_loc this#switch_case) cases in
    if discriminant == discriminant' && cases == cases' then switch
    else { discriminant = discriminant'; cases = cases' }

  method switch_case (case: (Loc.t, Loc.t) Flow_ast.Statement.Switch.Case.t') =
    let open Flow_ast.Statement.Switch.Case in
    let { test; consequent } = case in
    let test' = map_opt this#expression test in
    let consequent' = this#statement_list consequent in
    if test == test' && consequent == consequent' then case
    else { test = test'; consequent = consequent' }

  method tagged_template (expr: (Loc.t, Loc.t) Flow_ast.Expression.TaggedTemplate.t) =
    let open Flow_ast.Expression.TaggedTemplate in
    let { tag; quasi } = expr in
    let tag' = this#expression tag in
    let quasi' = map_loc this#template_literal quasi in
    if tag == tag' && quasi == quasi' then expr
    else { tag = tag'; quasi = quasi' }

  method template_literal (expr: (Loc.t, Loc.t) Flow_ast.Expression.TemplateLiteral.t) =
    let open Flow_ast.Expression.TemplateLiteral in
    let { quasis; expressions } = expr in
    let quasis' = ListUtils.ident_map this#template_literal_element quasis in
    let expressions' = ListUtils.ident_map this#expression expressions in
    if quasis == quasis' && expressions == expressions' then expr
    else { quasis = quasis'; expressions = expressions' }

  (* TODO *)
  method template_literal_element (elem: Loc.t Flow_ast.Expression.TemplateLiteral.Element.t) =
    elem

  method throw (stmt: (Loc.t, Loc.t) Flow_ast.Statement.Throw.t) =
    let open Flow_ast.Statement.Throw in
    let { argument } = stmt in
    id this#expression argument stmt (fun argument -> { argument })

  method try_catch (stmt: (Loc.t, Loc.t) Flow_ast.Statement.Try.t) =
    let open Flow_ast.Statement.Try in
    let { block = (block_loc, block); handler; finalizer } = stmt in
    let block' = this#block block in
    let handler' = match handler with
    | Some (loc, clause) ->
      id this#catch_clause clause handler (fun clause -> Some (loc, clause))
    | None -> handler
    in
    let finalizer' = match finalizer with
    | Some (finalizer_loc, block) ->
      id this#block block finalizer (fun block -> Some (finalizer_loc, block))
    | None -> finalizer
    in
    if block == block' && handler == handler' && finalizer == finalizer'
    then stmt
    else {
      block = (block_loc, block');
      handler = handler';
      finalizer = finalizer'
    }

  method type_cast (expr: (Loc.t, Loc.t) Flow_ast.Expression.TypeCast.t) =
    let open Flow_ast.Expression.TypeCast in
    let { expression; annot; } = expr in
    let expression' = this#expression expression in
    let annot' = this#type_annotation annot in
    if expression' == expression && annot' == annot then expr
    else { expression = expression'; annot = annot' }

  method unary_expression (expr: (Loc.t, Loc.t) Flow_ast.Expression.Unary.t) =
    let open Flow_ast.Expression in
    let { Unary.argument; operator = _; prefix = _ } = expr in
    id this#expression argument expr
      (fun argument -> { expr with Unary.argument })

  method update_expression (expr: (Loc.t, Loc.t) Flow_ast.Expression.Update.t) =
    let open Flow_ast.Expression.Update in
    let { argument; operator = _; prefix = _ } = expr in
    id this#expression argument expr (fun argument -> { expr with argument })

  method variable_declaration (decl: (Loc.t, Loc.t) Flow_ast.Statement.VariableDeclaration.t) =
    let open Flow_ast.Statement.VariableDeclaration in
    let { declarations; kind } = decl in
    let decls' = ListUtils.ident_map (this#variable_declarator ~kind) declarations in
    if declarations == decls' then decl
    else { declarations = decls'; kind }

  method variable_declarator ~kind (decl: (Loc.t, Loc.t) Flow_ast.Statement.VariableDeclaration.Declarator.t) =
    let open Flow_ast.Statement.VariableDeclaration.Declarator in
    let (loc, { id; init }) = decl in
    let id' = this#variable_declarator_pattern ~kind id in
    let init' = map_opt this#expression init in
    if id == id' && init == init' then decl
    else (loc, { id = id'; init = init' })

  method while_ (stuff: (Loc.t, Loc.t) Flow_ast.Statement.While.t) =
    let open Flow_ast.Statement.While in
    let { test; body } = stuff in
    let test' = this#predicate_expression test in
    let body' = this#statement body in
    if test == test' && body == body' then stuff
    else { test = test'; body = body' }

  method with_ (stuff: (Loc.t, Loc.t) Flow_ast.Statement.With.t) =
    let open Flow_ast.Statement.With in
    let { _object; body } = stuff in
    let _object' = this#expression _object in
    let body' = this#statement body in
    if _object == _object' && body == body' then stuff
    else { _object = _object'; body = body' }

  method type_alias (stuff: (Loc.t, Loc.t) Flow_ast.Statement.TypeAlias.t) =
    let open Flow_ast.Statement.TypeAlias in
    let { id; tparams; right } = stuff in
    let id' = this#identifier id in
    let tparams' = map_opt this#type_parameter_declaration tparams in
    let right' = this#type_ right in
    if id == id' && right == right' && tparams == tparams' then stuff
    else { id = id'; tparams = tparams'; right = right' }

  (* TODO *)
  method yield (expr: (Loc.t, Loc.t) Flow_ast.Expression.Yield.t) = expr

end

let fold_program mappers ast =
  List.fold_left (fun ast (m: mapper) -> m#program ast) ast mappers
