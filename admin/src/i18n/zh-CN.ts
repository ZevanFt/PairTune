export const zhCN = {
  app: {
    title: '合拍 PairTune 管理后台',
    subtitle: '运营与权限控制中心'
  },
  sidebar: {
    brandTop: 'PAIR',
    brandMain: 'Tune Admin'
  },
  topbar: {
    title: '运营控制台',
    tag: 'Admin Console',
    logout: '退出登录'
  },
  nav: {
    dashboard: '仪表盘',
    invites: '邀请码',
    users: '用户',
    tasks: '任务运营',
    points: '积分运营',
    store: '商城运营',
    security: '安全审计',
    roles: '角色权限',
    settings: '系统设置'
  },
  login: {
    title: '管理员登录',
    hint: '仅管理员可访问后台',
    account: '账号',
    password: '密码',
    action: '登录',
    accountPlaceholder: 'admin_account',
    passwordPlaceholder: '******',
    emptyError: '账号或密码不能为空',
    forbidden: '无管理员权限',
    failed: '登录失败'
  },
  dashboard: {
    headline: '运营概览',
    users: '活跃用户',
    tasks: '任务完成率',
    points: '积分净流通',
    store: '商城兑换量',
    range7: '近7天',
    range30: '近30天',
    range90: '近90天',
    growth: '用户增长趋势',
    overview: '任务与积分概览',
    waiting: '等待统计接口'
  },
  invites: {
    headline: '邀请码管理',
    create: '生成邀请码',
    disable: '禁用',
    count: '数量',
    limit: '使用次数',
    expires: '过期时间',
    subtitle: '用于注册的唯一凭证',
    loadFail: '加载邀请码失败',
    createFail: '生成邀请码失败',
    createOk: '邀请码已生成',
    disableOk: '邀请码已禁用',
    disableFail: '禁用失败',
    invalidInput: '请输入有效数量与使用次数',
    columns: {
      code: '邀请码',
      status: '状态',
      usage: '已用/总量',
      created: '创建时间',
      used: '使用时间',
      action: '操作'
    }
  },
  users: {
    headline: '用户列表',
    subtitle: '账号与角色概览',
    account: '账号',
    name: '昵称',
    role: '角色',
    status: '状态',
    created: '创建时间',
    loadFail: '加载用户失败'
  },
  roles: {
    headline: '角色与权限',
    create: '新建角色',
    update: '更新角色',
    subtitle: '页面级 + 功能点权限',
    name: '角色名称',
    description: '描述',
    perm: '权限配置',
    loadFail: '加载角色失败',
    saveOk: '角色保存成功',
    saveFail: '保存角色失败',
    validate: '请填写角色名称并选择权限',
    namePlaceholder: '例如：viewer',
    descPlaceholder: '选填描述',
    columns: {
      name: '角色名',
      desc: '描述',
      count: '权限数量',
      action: '操作',
      edit: '编辑'
    }
  },
  tasks: {
    subtitle: '任务运营指标汇总',
    waiting: '等待统计接口 /admin/stats/tasks'
  },
  points: {
    subtitle: '积分发放与消耗概览',
    waiting: '等待统计接口 /admin/stats/points'
  },
  store: {
    subtitle: '商城运营数据',
    waiting: '等待统计接口 /admin/stats/store'
  },
  security: {
    subtitle: '登录失败与安全事件',
    waiting: '等待安全审计接口'
  },
  settings: {
    subtitle: '系统配置与运行状态',
    waiting: '配置状态待接入'
  },
  common: {
    search: '搜索',
    refresh: '刷新',
    save: '保存',
    cancel: '取消',
    empty: '暂无数据',
    loading: '加载中',
    dash: '-',
    waiting: '等待统计接口'
  }
};
