class IndustrialsController < ApplicationController
  require 'base64'
  require 'open3'
  require 'json'

  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    file_path = save_uploaded_file(params[:file_data])
    return unless file_path

    output_dir = Rails.root.join('public', 'plots').to_s
    FileUtils.mkdir_p(output_dir)

    output = run_python_script(file_path, output_dir)

    if output["error"]
      render json: { error: output["error"] }, status: 500
      return
    end

    # Convert file paths to accessible URLs
    trend_plot_url = url_for_file(output["trend_plot"])
    heatmap_url = url_for_file(output["heatmap"])
    feature_importance_url = url_for_file(output["feature_importance_plot"])

    render json: {
      accuracy: output["accuracy"],
      classification_report: output["classification_report"],
      trend_plot_url: trend_plot_url,
      heatmap_url: heatmap_url,
      feature_importance_url: feature_importance_url
    }
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  private

  def save_uploaded_file(base64_data)
    return unless base64_data.present?

    decoded_data = Base64.decode64(base64_data)
    file_path = "/tmp/uploaded_file.xlsx"  # Use `/tmp/` for production

    File.open(file_path, 'wb') { |file| file.write(decoded_data) }
    file_path
  rescue StandardError => e
    Rails.logger.error("File upload error: #{e.message}")
    nil
  end

  def run_python_script(file_path, output_dir)
    script_path = Rails.root.join('lib', 'scripts', 'data_processing.py').to_s
    python_env = "python3"  # Use system Python directly

    output, error, status = Open3.capture3("#{python_env} #{script_path} #{file_path} #{output_dir}")

    if status.success?
      begin
        JSON.parse(output)
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parse error: #{e.message}")
        { error: "Invalid JSON response from Python script" }
      end
    else
      Rails.logger.error("Python script error: #{error}")
      { error: "Failed to process data" }
    end
  rescue StandardError => e
    Rails.logger.error("Execution error: #{e.message}")
    { error: "Failed to execute script" }
  end

  def url_for_file(file_path)
    return nil unless file_path && File.exist?(file_path)

    file_name = File.basename(file_path)
    "#{request.base_url}/plots/#{file_name}"
  end
end
