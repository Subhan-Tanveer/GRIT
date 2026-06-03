<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.grit-wrap { background: #0A0A0A; width: 360px; margin: 0 auto; font-family: 'Inter', sans-serif; }
.bc { font-family: 'Metropolis', sans-serif; }
.mono { font-family: 'Inter', sans-serif; }
.divider { height: 1px; background: #222222; }

/* Header */
.hdr { background: #111111; padding: 14px 20px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #222222; }
.hdr-left { display: flex; flex-direction: column; gap: 2px; }
.hdr-name { font-family: 'Metropolis', sans-serif; font-weight: 800; font-size: 20px; text-transform: uppercase; color: #EEEEEE; letter-spacing: 1px; }
.hdr-meta { font-family: 'Inter', sans-serif; font-weight: 300; font-size: 11px; color: #888888; }
.hdr-timer { font-family: 'Inter', monospace; font-weight: 700; font-size: 22px; color: #E94560; letter-spacing: 2px; }

/* Stats bar */
.stats-bar { display: flex; border-bottom: 1px solid #222222; }
.stat-cell { flex: 1; padding: 10px 20px; border-right: 1px solid #222222; }
.stat-cell:last-child { border-right: none; }
.stat-val { font-family: 'Inter', monospace; font-weight: 700; font-size: 16px; color: #EEEEEE; }
.stat-label { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: #888888; margin-top: 2px; }

/* Rest timer */
.rest-bar { background: rgba(233,69,96,0.06); border-bottom: 1px solid #222222; padding: 10px 20px; display: flex; align-items: center; gap: 12px; }
.rest-label { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 3px; color: #E94560; }
.rest-track { flex: 1; height: 2px; background: #222222; position: relative; }
.rest-fill { height: 2px; width: 60%; background: #E94560; }
.rest-time { font-family: 'Inter', monospace; font-weight: 700; font-size: 14px; color: #EEEEEE; }
.rest-actions { display: flex; gap: 12px; }
.rest-btn { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 2px; color: #888888; cursor: pointer; }

/* Exercise block */
.ex-block { border-bottom: 1px solid #222222; }
.ex-header { background: #111111; padding: 14px 20px 10px; border-bottom: 1px solid #222222; }
.ex-suggestion { display: inline-flex; align-items: center; gap: 4px; background: rgba(233,69,96,0.08); padding: 2px 8px; margin-bottom: 6px; }
.ex-suggestion span { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 2px; color: #E94560; }
.ex-name { font-family: 'Metropolis', sans-serif; font-weight: 800; font-size: 22px; text-transform: uppercase; color: #EEEEEE; }
.ex-sub { font-family: 'Inter', sans-serif; font-weight: 400; font-size: 11px; color: #888888; margin-top: 2px; }

/* Column headers */
.col-hdr { display: grid; grid-template-columns: 28px 1fr 20px 80px 44px; gap: 0; padding: 6px 20px; border-bottom: 1px solid #222222; }
.col-hdr span { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: #444444; }
.col-hdr .c-kg { }
.col-hdr .c-reps { text-align: center; }

/* Set rows */
.set-row { display: grid; grid-template-columns: 28px 1fr 20px 80px 44px; align-items: center; gap: 0; padding: 8px 20px; border-bottom: 1px solid #222222; min-height: 44px; }
.set-row.active { background: rgba(233,69,96,0.04); }
.set-row.done { background: rgba(46,204,113,0.03); }
.set-num { font-family: 'Inter', monospace; font-weight: 400; font-size: 11px; color: #444444; }
.set-input { background: #1A1A1A; border: 1px solid #222222; height: 32px; font-family: 'Inter', monospace; font-weight: 700; font-size: 15px; color: #EEEEEE; text-align: center; display: flex; align-items: center; justify-content: center; }
.set-input.focused { border-color: #E94560; }
.set-sep { font-family: 'Inter', monospace; font-weight: 400; font-size: 13px; color: #444444; text-align: center; }
.check-idle { width: 32px; height: 32px; border: 2px solid #222222; display: flex; align-items: center; justify-content: center; }
.check-done { width: 32px; height: 32px; background: #2ECC71; border: 2px solid #2ECC71; display: flex; align-items: center; justify-content: center; }
.check-done::after { content: '✓'; color: #000; font-size: 14px; font-weight: 700; }

/* Add set */
.add-set { padding: 12px 20px; display: flex; align-items: center; gap: 8px; cursor: pointer; }
.add-set span { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 12px; text-transform: uppercase; letter-spacing: 2px; color: #444444; }

/* Add exercise */
.add-ex { margin: 0 20px; border: 1px solid #222222; padding: 14px 20px; display: flex; align-items: center; justify-content: center; gap: 8px; cursor: pointer; }
.add-ex span { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 14px; text-transform: uppercase; letter-spacing: 3px; color: #888888; }

/* Finish */
.finish-wrap { padding: 16px 20px; }
.finish-btn { border: 1px solid #222222; padding: 0 20px; height: 48px; display: flex; align-items: center; justify-content: center; }
.finish-btn span { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 16px; text-transform: uppercase; letter-spacing: 3px; color: #888888; }

/* Nav */
.nav { background: #111111; border-top: 1px solid #222222; display: flex; height: 64px; }
.nav-tab { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px; position: relative; }
.nav-icon { font-size: 16px; color: #444444; }
.nav-icon.active { color: #E94560; }
.nav-lbl { font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 9px; text-transform: uppercase; letter-spacing: 1.5px; color: #444444; }
.nav-lbl.active { color: #E94560; }

.concept-tag { background: #E94560; padding: 4px 12px; font-family: 'Metropolis', sans-serif; font-weight: 700; font-size: 10px; text-transform: uppercase; letter-spacing: 3px; color: #fff; display: inline-block; margin-bottom: 8px; }
.concept-desc { font-family: 'Inter', sans-serif; font-size: 12px; color: #888888; margin-bottom: 12px; line-height: 1.5; }
</style>

<div style="background:#0A0A0A; padding: 20px 0;">
<div style="padding: 0 20px 12px;">
<div class="concept-tag">Concept A — Pure Spec</div>
<div class="concept-desc">Strict adherence to the doc. 5-column grid, brutalist flat surfaces, max information density. Everything per spec.</div>
</div>

<div class="grit-wrap">
<!-- Header -->
<div class="hdr">
<div class="hdr-left">
<div class="hdr-name">Push Day A</div>
<div class="hdr-meta">4 of 6 exercises</div>
</div>
<div class="hdr-timer">00:34:12</div>
</div>

<!-- Stats bar -->
<div class="stats-bar">
<div class="stat-cell">
<div class="stat-val mono">18</div>
<div class="stat-label">Sets Done</div>
</div>
<div class="stat-cell">
<div class="stat-val mono">2,340</div>
<div class="stat-label">Vol KG</div>
</div>
<div class="stat-cell">
<div class="stat-val mono" style="color:#E94560">2</div>
<div class="stat-label">PRs Today</div>
</div>
</div>

<!-- Rest Timer -->
<div class="rest-bar">
<div class="rest-label">REST</div>
<div class="rest-track"><div class="rest-fill"></div></div>
<div class="rest-time">1:24</div>
<div class="rest-actions">
<div class="rest-btn">+30s</div>
<div class="rest-btn" style="color:#888">SKIP</div>
</div>
</div>

<!-- Exercise 1 -->
<div class="ex-block">
<div class="ex-header">
<div class="ex-suggestion"><span>↑ Try 107.5 kg</span></div>
<div class="ex-name">Bench Press</div>
<div class="ex-sub">Chest · 3 × 8–12 · 90s rest</div>
</div>

<!-- Column headers -->
<div class="col-hdr">
<span>#</span>
<span>KG</span>
<span></span>
<span class="c-reps">REPS</span>
<span></span>
</div>

<!-- Set 1 - active -->
<div class="set-row active">
<div class="set-num">1</div>
<div class="set-input focused" style="font-size:15px">100.0</div>
<div class="set-sep">×</div>
<div class="set-input focused" style="font-size:15px">10</div>
<div style="display:flex;justify-content:center"><div class="check-idle"></div></div>
</div>

<!-- Set 2 - done + PR -->
<div class="set-row done">
<div class="set-num">2</div>
<div class="set-input">105.0</div>
<div class="set-sep">×</div>
<div class="set-input">8</div>
<div style="display:flex;justify-content:center; align-items:center; gap:4px; position:relative">
<div style="position:absolute; top:-6px; right:0; background:#E94560; padding:1px 4px; font-family:'Metropolis',sans-serif; font-weight:700; font-size:8px; letter-spacing:2px; color:#fff; text-transform:uppercase;">PR</div>
<div class="check-done"></div>
</div>
</div>

<!-- Set 3 -->
<div class="set-row">
<div class="set-num">3</div>
<div class="set-input">105.0</div>
<div class="set-sep">×</div>
<div class="set-input">8</div>
<div style="display:flex;justify-content:center"><div class="check-idle"></div></div>
</div>

<div class="add-set">
<span style="color:#E94560;font-size:16px">+</span>
<span>Add Set</span>
</div>
</div>

<!-- Exercise 2 (collapsed preview) -->
<div class="ex-block">
<div class="ex-header">
<div class="ex-suggestion"><span>↑ Try 72.5 kg</span></div>
<div class="ex-name">Overhead Press</div>
<div class="ex-sub">Shoulders · 3 × 8–12 · 90s rest</div>
</div>
<div class="col-hdr"><span>#</span><span>KG</span><span></span><span>REPS</span><span></span></div>
<div class="set-row">
<div class="set-num">1</div>
<div class="set-input">70.0</div>
<div class="set-sep">×</div>
<div class="set-input">10</div>
<div style="display:flex;justify-content:center"><div class="check-idle"></div></div>
</div>
<div class="add-set"><span style="color:#E94560;font-size:16px">+</span><span>Add Set</span></div>
</div>

<!-- Add exercise -->
<div style="padding: 16px 20px;">
<div class="add-ex"><span>+ Add Exercise</span></div>
</div>

<!-- Finish -->
<div class="finish-wrap">
<div class="finish-btn"><span>Finish Workout</span></div>
</div>

<!-- Nav -->
<div class="nav">
<div class="nav-tab"><div class="nav-icon">📅</div><div class="nav-lbl">This Week</div></div>
<div class="nav-tab active"><div class="nav-icon active" style="color:#E94560">🏋</div><div class="nav-lbl active">Workout</div></div>
<div class="nav-tab"><div class="nav-icon">👤</div><div class="nav-lbl">Profile</div></div>
</div>
</div>
</div>
