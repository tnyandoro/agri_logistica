import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

export default class extends Controller {
  static values = { data: Object }

  connect() {
    const ctx = this.element.getContext('2d')
    new Chart(ctx, this.dataValue)
  }
}
