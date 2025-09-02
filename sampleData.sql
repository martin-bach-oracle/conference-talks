insert into todo_users (user_id, username, email, created_date) values
(1, 'steve', 'steve@somewhere.com', sysdate),
(2, 'ben', 'ben@somewhere.com', sysdate),
(3, 'hannah', 'hannal@somewhere.com', sysdate),
(4, 'pete', 'pete@somewhere.com', sysdate);

insert into todo_categories (category_id, user_id, category_name, created_date) values
(1, 1, 'default', sysdate),
(2, 2, 'default', sysdate),
(3, 3, 'default', sysdate),
(4, 4, 'default', sysdate),
(5, 4, 'urgent', sysdate);

insert into todo_items set
(item_id = 1, user_id = 4, category_id = 4, title = 'do something, pete', description = 'a dummy thing to indicate a normal priority task for pete', priority = 'NORMAL', target_date = add_months(sysdate, 1), completion_date = null, created_date = sysdate),
(item_id = 2, user_id = 4, category_id = 4, title = 'do something urgently, pete!', description = 'a dummy thing to indicate a high priority task for pete', priority = 'HIGH', target_date = sysdate +2, completion_date = null, created_date = sysdate),
(item_id = 3, user_id = 1, category_id = 1, title = 'something for steve to do', description = 'a dummy thing to indicate a low priority task', priority = 'LOW', target_date = add_months(sysdate, 12), completion_date = null, created_date = sysdate);

commit;