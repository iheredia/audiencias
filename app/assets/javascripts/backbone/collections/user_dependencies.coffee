class audiencias.collections.UserDependencies extends Backbone.Collection
  model: audiencias.models.Dependency
  idAttribute: 'id'

  expandParents: (dependency) ->
    if dependency.get('parent_id')
      parent = @get(dependency.get('parent_id'))
      if parent
        parent.set('expanded', true, {silent: true})
        @expandParents(parent)
    else
      @trigger('change')

  setSelected: (dependencyId) ->
    @deselectAll()
    newSelectedDependency = @get(dependencyId)
    newSelectedDependency.set('selected', true)
    newSelectedDependency.toggleExpanded()
    @expandParents(newSelectedDependency)

  deselectAll: ->
    @filter((d) -> d.get('selected')).forEach((d) -> d.set('selected', false, {silent: true}))
    @trigger('change')

  forceUpdate: (newDependency) ->
    savedDependency = @get(newDependency.id)
    if savedDependency
      savedDependency.set(newDependency)
      savedDependency.set('users', newDependency.users)
      savedDependency.set('obligee', newDependency.obligee)
      savedDependency.saveState()
    else 
      @add(newDependency)

  removeAndUpdateParentOf: (dependency) =>
    @remove(dependency)
    parent = @get(dependency.get('parent_id'))
    if parent 
      siblings = @filter( (d) -> d.get('parent_id') == parent.get('id') )
      if siblings.length == 0
        parent.set('expanded', false)
