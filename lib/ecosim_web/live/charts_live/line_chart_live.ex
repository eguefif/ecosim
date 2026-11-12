defmodule EcosimWeb.ChartsLive.LineChartLive do
  use EcosimWeb, :live_view

  attr :title, :string, required: true
  attr :labels, :list, required: true
  attr :values, :list, doc: "[[x1, y1], [x2, y2]...]"

  def plot_line(assigns) do
    ~H"""
    <div class="relative h-[300px]">
      <canvas
        id={"#{@title}-line-chart"}
        phx-hook=".LineChart"
        phx-update="ignore"
        data-chart={Jason.encode!(%{title: @title, labels: @labels, values: @values})}
      ></canvas>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".LineChart">
        import Chart from "chart.js/auto"

        export default {
          mounted() {
            const {title, labels, values} = JSON.parse(this.el.dataset.chart)
            console.log(values)

            const datasets = []
            for (const [label, data] of Iterator.zip([labels, values])) {
              datasets.push({
                label: label,
                data: data,
                borderWidth: 1
              })
            }

            this.chart = new Chart(this.el, {
              type: "line",
              data: {
                datasets: datasets,
              },
              options: {
                maintainAspectRatio: false,
                scales: {
                  x: {type: "linear"}
                }
              }
            })
          },
        destroyed() {
          this.chart.destroy()
        }
      }
    </script>
    """
  end
end
