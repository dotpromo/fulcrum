describe("Fulcrum.ColumnVisibilityButtonView", function() {

  beforeEach(function() {
    this.columnView = new Fulcrum.ColumnView({
      name: 'Dummy',
      id: 'fakeId'
    });
    this.view = new Fulcrum.ColumnVisibilityButtonView({columnView: this.columnView});
  });

  it("should have <a> as the tagName",function() {
    expect(this.view.el.nodeName).toEqual('A');
  });

  it("should set its content from the ColumnView title", function() {
    expect(this.view.render().$el.html()).toEqual(this.columnView.name);
  });

  it("should set its class from the ColumnView id", function() {
    expect(this.view.render().$el.attr('class')).toEqual('hide_' + this.columnView.id);
  });

  describe('toggle', function() {

    beforeEach(function() {
      this.columnView.toggle = sinon.stub();
    });

    it('delegates to the columnView', function() {
      this.view.toggle();
      expect(this.columnView.toggle).toHaveBeenCalled();
    });

  });

  describe('setClassName', function() {
    it("sets the pressed class when the column is hidden", function() {
      this.columnView.hidden = sinon.stub().returns(true);
      this.view.setClassName();
      expect(this.view.$el).toHaveClass('pressed');
    });

    it("removes the pressed class when the column is visible", function() {
      this.columnView.hidden = sinon.stub().returns(false);
      this.view.setClassName();
      expect(this.view.$el).not.toHaveClass('pressed');
    });

    // TODO: Found better way how to spy on listenTo
    /*it("is bound to the columnView visibilityChanged event", function() {
      expect(this.view.listenTo).toHaveBeenCalledWith(
        this.columnView, 'visibilityChanged', this.view.setClassName
      );
    });*/
  });
});
