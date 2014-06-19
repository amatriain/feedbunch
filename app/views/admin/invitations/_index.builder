context.instance_eval  do
  h2 'Invitations sent'
  table_for(invitations, :sortable => true, :class => 'index_table') do |invitation|
    column :id
    column :email
    column :invitation_sent_at
    column :invitation_accepted_at
    column do |invitation|
      link_to 'View', "/admin/users/#{invitation.id}"
    end
  end
end