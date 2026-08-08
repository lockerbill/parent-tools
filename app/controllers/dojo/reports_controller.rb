module Dojo
  class ReportsController < BaseController
    DAYS = 30

    def show
      @child = children_scope.find(params[:id])
      @report = Dojo::ChildReport.new(@child, days: DAYS)
    end
  end
end
