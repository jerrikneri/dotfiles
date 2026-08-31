# Stand-up - {{date}}

## Weekly Goals
<!-- First workday of the week? Fill in this week's goals below. Every other day this week pulls them automatically. -->
- [ ] placeholder
```dataview
LIST WITHOUT ID rows.item.text
FROM #standup
WHERE file.day < this.file.day AND dateformat(file.day, "kkkk-'W'WW") = dateformat(this.file.day, "kkkk-'W'WW")
FLATTEN file.lists AS item
WHERE meta(item.section).subpath = "Weekly Goals" AND item.text
GROUP BY file.day
SORT key ASC
LIMIT 1
```

## Daily Goals
- [ ] placeholder

## Yesterday
```dataview
LIST WITHOUT ID rows.item.text
FROM #standup
WHERE file.day < this.file.day
FLATTEN file.lists AS item
WHERE meta(item.section).subpath = "Today"
GROUP BY file.day
SORT key DESC
LIMIT 1
```

## Today
- 

## Blockers / Impediments
- 

***
#standup #work
