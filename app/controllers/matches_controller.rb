class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, except: [:index, :show] 

  # GET /matches
  # GET /matches.json
  def index
    params[:page] ||=1
    @matches = Match.paginate(:page => params[:page], :per_page => 10)
  end

  # GET /matches/1
  # GET /matches/1.json
  def show
  end

  # GET /matches/new
  def new
    @match = Match.new
  end

  # GET /matches/1/edit
  def edit
  end

  # POST /matches
  # POST /matches.json
  def create
    @match = Match.new(match_params)
    @match.player1_id = params[:match][:player1_id]
    @match.player2_id = params[:match][:player2_id]

    respond_to do |format|
      if @match.save
        format.html { redirect_to @match, notice: 'Match was successfully created.' }
        format.json { render action: 'show', status: :created, location: @match }
      else
        format.html { render action: 'new' }
        format.json { render json: @match.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /matches/1
  # PATCH/PUT /matches/1.json
  def update
    @match.player1_id = params[:match][:player1_id]
    @match.player2_id = params[:match][:player2_id]

    respond_to do |format|
      if @match.update(match_params)
        format.html { redirect_to @match, notice: 'Match was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @match.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /matches/1
  # DELETE /matches/1.json
  def destroy
    @match.destroy
    respond_to do |format|
      format.html { redirect_to matches_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_match
      @match = Match.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def match_params
      params.require(:match).permit(:status, :player1_id, :player2_id, :score1, :score2, :player1, :player2)
    end
end
