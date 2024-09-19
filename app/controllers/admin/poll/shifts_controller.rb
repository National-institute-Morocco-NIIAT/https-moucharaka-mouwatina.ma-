class Admin::Poll::ShiftsController < Admin::Poll::BaseController
  before_action :load_booth
  before_action :load_officer

  def new
    load_shifts
    @shift = ::Poll::Shift.new
    @voting_polls = @booth.polls.current
    @recount_polls = @booth.polls.current_or_recounting
  end

  def create
    @shift = ::Poll::Shift.new(shift_params)
    @officer = @shift.officer

    if @shift.save
      notice = t("admin.poll_shifts.flash.create")
      redirect_to new_admin_booth_shift_path(@shift.booth), notice: notice
    else
      load_shifts
      flash[:error] = t("admin.poll_shifts.flash.date_missing")
      render :new
    end
  end

  def destroy
    @shift = Poll::Shift.find(params[:id])
    if @shift.unable_to_destroy?
      alert = t("admin.poll_shifts.flash.unable_to_destroy")
      redirect_to new_admin_booth_shift_path(@booth), alert: alert
    else
      @shift.destroy!
      notice = t("admin.poll_shifts.flash.destroy")
      redirect_to new_admin_booth_shift_path(@booth), notice: notice
    end
  end

  def search_officers
    @officers = User.search(params[:search]).order(username: :asc).select(&:poll_officer?)
  end

  private

    def load_booth
      @booth = ::Poll::Booth.find(params[:booth_id])
    end

    def load_shifts
      @shifts = @booth.shifts
    end

    def load_officer
      if params[:officer_id].present?
        @officer = ::Poll::Officer.find(params[:officer_id])
      end
    end

    def shift_params
      shift_params = params.require(:shift).permit(allowed_params)
      shift_params.merge(date: shift_params[:date][:"#{shift_params[:task]}_date"])
    end

    def allowed_params
      date_attributes = [:vote_collection_date, :recount_scrutiny_date]

      [:booth_id, :officer_id, :task, date: date_attributes]
    end
end
