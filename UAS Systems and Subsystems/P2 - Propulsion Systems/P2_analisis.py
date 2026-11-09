"""P2: ensayo del motor en vacío. Uso: /usr/local/bin/python3 P2_analisis.py
Lee P2_medidas.csv y deja Parte3_motor_vacio.csv y figuras/fig_motor.pdf."""
from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parent
R_SHUNT_OHM = 0.1 / 20      # 20 A <-> 100 mV
V_BAT_V = 24.8              # tensión de la batería 6S en el ensayo
PAR_POLOS = 7               # estimado con el Jeti; se comprueba abajo

d = pd.read_csv(BASE / "P2_medidas.csv")
d["i_a"] = d.v_shunt_mv / 1000 / R_SHUNT_OHM
d["p_w"] = d.i_a * V_BAT_V
d["rpm_osc"] = d.f_osc_hz * 60 / PAR_POLOS
d["pares_polos"] = d.f_osc_hz * 60 / d.rpm_jeti
d["err_rpm_pct"] = 100 * (d.rpm_osc - d.rpm_jeti) / d.rpm_jeti
d.round(3).to_csv(BASE / "Parte3_motor_vacio.csv", index=False)
print(d.round(2).to_string(index=False))
assert abs(d.pares_polos.dropna().mean() - PAR_POLOS) < 0.2

fig, (a, b) = plt.subplots(1, 2, figsize=(6.3, 2.5))
a.plot(d.pwm_pct, d.rpm_osc, "o-", label="Osciloscopio")
a.plot(d.pwm_pct, d.rpm_jeti, "s", label="Jeti")
a.set(xlabel="PWM [%]", ylabel="rpm"); a.legend()
b.plot(d.pwm_pct, d.p_w, "o-")
b.set(xlabel="PWM [%]", ylabel="Potencia en vacío [W]")
fig.tight_layout()
fig.savefig(BASE / "figuras" / "fig_motor.pdf")
