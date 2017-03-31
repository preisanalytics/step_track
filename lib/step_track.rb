# frozen_string_literal: true

module StepTrack
  extend self

  REF = "step_track/%{track}"

  def init(track, config={merge_key: :merge, error_key: :error})
    raise ArgumentError, "callback block required" unless block_given?
    Thread.current[ref(track)] = {
      steps: [],
      callback: Proc.new,
      time: Time.now
    }.merge(config)
  end

  def push(track, name, payload={})
    require_init!(track)
    track_ref = Thread.current[ref(track)]
    return if track_ref[:steps].last&.[](track_ref[:error_key])
    merge_step = track_ref[:steps].pop if payload.delete(track_ref[:merge_key])
    last_step = track_ref[:steps].last
    track_ref[:steps] << (merge_step || {}).merge(
      split: Time.now.to_f - (last_step&.[](:time) || track_ref[:time]).to_f,
      duration: Time.now.to_f - track_ref[:time].to_f,
      time: Time.now,
      caller: merge_step&.[](:caller) || caller[0].sub(Dir.pwd + "/", ""),
      name: merge_step&.[](:name) || name
    ).merge(payload)
  end

  def done(track)
    require_init!(track)
    track_ref = Thread.current[ref(track)]
    Thread.current[ref(track)] = nil
    steps = track_ref.delete(:steps)
    steps.each { |step| step.delete(:time) }
    result = {step_count: steps.count}
    result.merge!(steps.last || {})
    steps.each_with_index do |step, i|
      name = step[:name]
      [:split, :duration].each { |k| step[k] = (step[k] * 1000).to_i }
      result.merge!(step.merge(i: i + 1).
        map { |k, v| ["step_#{name}_#{k}".to_sym, v] }.to_h)
    end
    return track_ref[:callback].call(result)
  end

  private

  def ref(track)
    (REF % {track: track}).to_sym
  end

  def initialized?(track)
    !Thread.current[ref(track)].nil?
  end

  def require_init!(track)
    raise ArgumentError, "track not initialized" unless initialized?(track)
  end
end
