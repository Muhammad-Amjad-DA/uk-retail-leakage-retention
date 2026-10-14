"""Builds the README images from outputs/*.csv. Run after run_analysis.py."""
import pathlib, pandas as pd, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

root = pathlib.Path(__file__).resolve().parents[1]
out, img = root / "outputs", root / "images"; img.mkdir(exist_ok=True)
NAVY, ORANGE, GREY, LIGHT = "#1F3A5F", "#E07A1F", "#8A94A3", "#E8ECF1"
plt.rcParams.update({"font.family": "DejaVu Sans", "axes.spines.top": False, "axes.spines.right": False,
                     "axes.edgecolor": GREY, "axes.labelcolor": "#333", "xtick.color": "#333", "ytick.color": "#333"})

# 1) Hero: headline vs genuine return rate
r = pd.read_csv(out / "03_returns_leakage_q1.csv")
r = r[r.yr >= 2010]
fig, ax = plt.subplots(figsize=(12, 6.3), dpi=100)
x = range(len(r)); w = 0.36
b1 = ax.bar([i - w/2 for i in x], r.return_rate_headline_pct, w, color=GREY, label="Headline (all credit notes)")
b2 = ax.bar([i + w/2 for i in x], r.return_rate_genuine_pct, w, color=NAVY, label="After removing order-and-cancel errors")
for b in list(b1) + list(b2):
    ax.text(b.get_x() + b.get_width()/2, b.get_height() + 0.08, f"{b.get_height():.2f}%", ha="center", fontsize=12, fontweight="bold")
ax.set_xticks(list(x)); ax.set_xticklabels(r.yr.astype(int), fontsize=13)
ax.set_ylim(0, 6.2); ax.set_yticks([]); ax.spines["left"].set_visible(False)
ax.legend(frameon=False, fontsize=11, loc="upper left")
ax.annotate("Two same-day order-and-cancel\nentries = £245,653 (34% of all\nreturned value)", xy=(1 - w/2, 4.84), xytext=(0.15, 5.2),
            fontsize=10.5, color=ORANGE, arrowprops=dict(arrowstyle="->", color=ORANGE))
fig.suptitle("2011 return rate looks like 4.8%. It is really 2.3%.", x=0.06, ha="left", fontsize=20, fontweight="bold", color=NAVY)
fig.text(0.06, 0.88, "UK online retailer (mostly wholesale buyers), return rate by value, 2010 vs 2011", fontsize=12, color=GREY)
fig.tight_layout(rect=[0, 0, 1, 0.86]); fig.savefig(img / "hero_return_rate.png"); plt.close(fig)

# 3) Cohort retention heatmap
c = pd.read_csv(out / "04_cohort_retention_q1.csv")
c["cohort"] = pd.to_datetime(c.cohort_month).dt.strftime("%b %Y")
p = c.pivot(index="cohort", columns="month_n", values="retention_pct")
p = p.reindex(pd.to_datetime(c.cohort_month.unique()).strftime("%b %Y"))
p = p[[i for i in range(0, 13)]]
fig, ax = plt.subplots(figsize=(12, 6.3), dpi=100)
im = ax.imshow(p.drop(columns=0).values, cmap="Blues", aspect="auto", vmin=0, vmax=35)
ax.set_xticks(range(12)); ax.set_xticklabels(range(1, 13)); ax.set_yticks(range(len(p))); ax.set_yticklabels(p.index)
for i in range(p.shape[0]):
    for j in range(1, 13):
        v = p.iloc[i, j]
        if pd.notna(v): ax.text(j - 1, i, f"{v:.0f}", ha="center", va="center", fontsize=9, color="white" if v > 20 else "#333")
ax.set_xlabel("Months since first order"); ax.spines[:].set_visible(False)
fig.suptitle("70% of customers reorder within a year, but only ~20% in any single month", x=0.06, ha="left", fontsize=19, fontweight="bold", color=NAVY)
fig.text(0.06, 0.88, "% of each monthly cohort active in month N (customers first seen Jan-Nov 2010). Ordering is episodic, not monthly", fontsize=11.5, color=GREY)
fig.tight_layout(rect=[0, 0, 1, 0.86]); fig.savefig(img / "cohort_retention.png"); plt.close(fig)

# 4) RFM: customers vs revenue share
s = pd.read_csv(out / "05_rfm_segments_q1.csv"); s["name"] = s.segment.str[2:]
fig, ax = plt.subplots(figsize=(12, 6.3), dpi=100)
y = range(len(s)); h = 0.38
ax.barh([i + h/2 for i in y], s.pct_customers, h, color=GREY, label="% of customers")
ax.barh([i - h/2 for i in y], s.pct_revenue, h, color=NAVY, label="% of net revenue")
for i, (pc, pr) in enumerate(zip(s.pct_customers, s.pct_revenue)):
    ax.text(pc + 0.8, i + h/2, f"{pc:.1f}%", va="center", fontsize=11); ax.text(pr + 0.8, i - h/2, f"{pr:.1f}%", va="center", fontsize=11, fontweight="bold")
ax.set_yticks(list(y)); ax.set_yticklabels(s.name, fontsize=12); ax.invert_yaxis(); ax.set_xticks([]); ax.spines["bottom"].set_visible(False)
ax.legend(frameon=False, loc="lower right", fontsize=11)
fig.suptitle("23.5% of customers generate 69.5% of net revenue", x=0.06, ha="left", fontsize=20, fontweight="bold", color=NAVY)
fig.text(0.06, 0.88, "423 'at risk' customers hold £1.06M of lifetime revenue and have not ordered for a median 338 days", fontsize=11.5, color=GREY)
fig.tight_layout(rect=[0, 0, 1, 0.86]); fig.savefig(img / "rfm_segments.png"); plt.close(fig)
print("ok")
