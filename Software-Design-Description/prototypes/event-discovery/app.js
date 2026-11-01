/**
 * UniScout — Calendar Controller (Orbit Design Model)
 * Matches the reference design with high-fidelity interactivity
 */

document.addEventListener('DOMContentLoaded', () => {

  // Event dataset matching the reference image exactly
  const EVENTS = [
    {
      id: 'EVT-01',
      day: 1,
      time: '10:00 AM',
      title: 'AI Workshop',
      category: 'Seminar',
      badgeClass: 'seminar',
      venue: 'Block D, Software Lab 2',
      organizer: 'Computer Science Society',
      desc: 'Hands-on practical exploration of Large Language Models and intelligent agent architectures.'
    },
    {
      id: 'EVT-02',
      day: 2,
      time: '2:00 PM',
      title: 'Career Talk',
      category: 'Sports',
      badgeClass: 'sports',
      venue: 'Main Auditorium Al-Muktafi',
      organizer: 'Career & Counseling Center',
      desc: 'Navigating graduate job placement and software engineering recruitment pipelines.'
    },
    {
      id: 'EVT-03',
      day: 3,
      time: '9:00 AM',
      title: 'Hackathon Briefing',
      category: 'Competition',
      badgeClass: 'competition',
      venue: 'Innovation Incubator Lab',
      organizer: 'Faculty of Informatics & Computing',
      desc: 'Technical briefing and problem statement disclosure for the annual campus hackathon.'
    },
    {
      id: 'EVT-04',
      day: 5,
      time: '1:00 PM',
      title: 'Volunteering Drive',
      category: 'Career',
      badgeClass: 'career',
      venue: 'Student Center Grounds',
      organizer: 'HEPA Volunteer Corps',
      desc: 'Community mobilization and flood disaster preparedness training.'
    },
    {
      id: 'EVT-05',
      day: 7,
      time: '3:00 PM',
      title: 'Web Development Workshop',
      category: 'Workshop',
      badgeClass: 'workshop',
      venue: 'Software Lab 3, Block D',
      organizer: 'Computer Science Society',
      desc: 'Mastering modern HTML5, CSS layout grids, and full-stack API integration.'
    },
    {
      id: 'EVT-06',
      day: 8,
      time: '10:00 AM',
      title: 'Internship Fair',
      category: 'Career',
      badgeClass: 'career',
      venue: 'Dewan Perdana Gong Badak',
      organizer: 'FIK Industrial Liaison Office',
      desc: 'On-campus interviews with over 30 leading software and technology employers.'
    },
    {
      id: 'EVT-07',
      day: 9,
      time: '2:00 PM',
      title: 'Data Science Seminar',
      category: 'Seminar',
      badgeClass: 'seminar',
      venue: 'Auditorium Academic Block',
      organizer: 'Department of Analytics',
      desc: 'Keynote symposium on predictive modeling and big data analytics.'
    },
    {
      id: 'EVT-08',
      day: 10,
      time: '9:00 AM',
      title: 'Sports Day',
      category: 'Sports',
      badgeClass: 'sports',
      venue: 'UniSZA Sports Complex',
      organizer: 'Sports & Recreation Centre',
      desc: 'Inter-faculty athletic competitions, track events, and badminton tournaments.'
    },
    {
      id: 'EVT-09',
      day: 12,
      time: '10:00 AM',
      title: 'Business Case Competition',
      category: 'Competition',
      badgeClass: 'competition',
      venue: 'Block C, Lecture Hall',
      organizer: 'Faculty of Business & Management',
      desc: 'Sprint competition solving real-world enterprise strategy challenges.'
    },
    {
      id: 'EVT-10',
      day: 13,
      time: '1:00 PM',
      title: 'Community Service (Orphanage)',
      category: 'Volunteering',
      badgeClass: 'volunteering',
      venue: 'Rumah Anak Yatim Kuala Terengganu',
      organizer: 'Bakti Siswa Club',
      desc: 'Charity outreach, digital literacy mentoring, and recreational activities.'
    },
    {
      id: 'EVT-11',
      day: 15,
      time: '11:00 AM',
      title: 'UI/UX Workshop',
      category: 'Seminar',
      badgeClass: 'seminar',
      venue: 'Block B, Lab 3',
      organizer: 'Computer Science Society',
      desc: 'Comprehensive masterclass on Figma design tokens, user experience architecture, and usability testing.'
    },
    {
      id: 'EVT-12',
      day: 16,
      time: '2:00 PM',
      title: 'Industry Talk',
      category: 'Workshop',
      badgeClass: 'workshop',
      venue: 'DAC Auditorium',
      organizer: 'UniSZA Tech Alumni',
      desc: 'Executive talk by senior engineering managers from leading Southeast Asian tech firms.'
    },
    {
      id: 'EVT-13',
      day: 17,
      time: '9:00 AM',
      title: 'Hackathon',
      category: 'Career',
      badgeClass: 'career',
      venue: 'Innovation Centre',
      organizer: 'FIK Software Development Guild',
      desc: '24-hour sprint prototyping innovative campus solutions.'
    },
    {
      id: 'EVT-14',
      day: 18,
      time: '3:00 PM',
      title: 'Career Fair',
      category: 'Competition',
      badgeClass: 'competition',
      venue: 'Student Center Hall',
      organizer: 'HEPA Career Unit',
      desc: 'Resume clinics, speed-networking, and employer career booths.'
    },
    {
      id: 'EVT-15',
      day: 20,
      time: '10:00 AM',
      title: 'Environmental Campaign',
      category: 'Sports',
      badgeClass: 'sports',
      venue: 'University Park & Coastal Track',
      organizer: 'Green Campus Secretariat',
      desc: 'Beach cleanup, coastal tree planting, and sustainability workshops.'
    },
    {
      id: 'EVT-16',
      day: 21,
      time: '2:00 PM',
      title: 'Tech Talk',
      category: 'Career',
      badgeClass: 'career',
      venue: 'Auditorium Block D',
      organizer: 'Google Developer Student Club',
      desc: 'Exploring modern cloud-native deployment patterns and microservice reliability.'
    },
    {
      id: 'EVT-17',
      day: 23,
      time: '10:00 AM',
      title: 'Leadership Workshop',
      category: 'Seminar',
      badgeClass: 'seminar',
      venue: 'Senate Room, Chancellery',
      organizer: 'Student Representative Council',
      desc: 'Empowering campus student leaders with strategic communication and conflict resolution skills.'
    },
    {
      id: 'EVT-18',
      day: 24,
      time: '1:00 PM',
      title: 'Resume Clinic',
      category: 'Workshop',
      badgeClass: 'workshop',
      venue: 'Block D, Discussion Room 4',
      organizer: 'Career Services',
      desc: '1-on-1 resume critiques, portfolio reviews, and mock behavioral interviews.'
    },
    {
      id: 'EVT-19',
      day: 26,
      time: '9:00 AM',
      title: 'Charity Run',
      category: 'Volunteering',
      badgeClass: 'volunteering',
      venue: 'UniSZA Track & Telipot Coast',
      organizer: 'Sports Council',
      desc: '5KM wellness run raising scholarships for underprivileged students.'
    },
    {
      id: 'EVT-20',
      day: 27,
      time: '3:00 PM',
      title: 'Design Thinking Workshop',
      category: 'Competition',
      badgeClass: 'competition',
      venue: 'Design Studio Lab',
      organizer: 'Innovation Unit',
      desc: 'Human-centered design sprint focusing on empathy mapping and rapid prototyping.'
    },
    {
      id: 'EVT-21',
      day: 29,
      time: '10:00 AM',
      title: 'Scholarship Talk',
      category: 'Career',
      badgeClass: 'career',
      venue: 'Dewan Kuliah 1',
      organizer: 'Academic Affairs Office',
      desc: 'Briefing on postgraduate scholarships, exchange programs, and funding opportunities.'
    },
    {
      id: 'EVT-22',
      day: 30,
      time: '2:00 PM',
      title: 'Networking Event',
      category: 'Sports',
      badgeClass: 'sports',
      venue: 'Lakeside Pavilion',
      organizer: 'Undergraduate Alumni Network',
      desc: 'Casual alumni mixer connecting final-year students with working tech professionals.'
    }
  ];

  // Upcoming items on right panel
  const UPCOMING = [
    {
      day: '15',
      month: 'APR',
      title: 'UI/UX Workshop',
      time: '10:00 AM – 12:00 PM',
      venue: 'Block B, Lab 3',
      colorClass: 'purple'
    },
    {
      day: '16',
      month: 'APR',
      title: 'Industry Talk',
      time: '2:00 PM – 4:00 PM',
      venue: 'DAC Auditorium',
      colorClass: 'orange'
    },
    {
      day: '17',
      month: 'APR',
      title: 'Hackathon',
      time: '9:00 AM – 6:00 PM',
      venue: 'Innovation Centre',
      colorClass: 'blue'
    },
    {
      day: '19',
      month: 'APR',
      title: 'Business Case Competition',
      time: '10:00 AM – 1:00 PM',
      venue: 'Block C, Lecture Hall',
      colorClass: 'red'
    },
    {
      day: '20',
      month: 'APR',
      title: 'Environmental Campaign',
      time: '10:00 AM – 1:00 PM',
      venue: 'University Park',
      colorClass: 'green'
    }
  ];

  // DOM Elements
  const calendarGrid = document.getElementById('calendar-days-grid');
  const upcomingList = document.getElementById('upcoming-events-list');
  const categoryCheckboxes = document.querySelectorAll('.category-filter-item input[type="checkbox"]');
  const btnClearCategories = document.getElementById('btn-clear-categories');
  const globalSearchInput = document.getElementById('global-search');
  const viewSegments = document.querySelectorAll('.btn-segment');

  // Modal Elements
  const detailModal = document.getElementById('event-detail-modal');
  const btnModalClose = document.getElementById('btn-modal-close');
  const modalCategoryTag = document.getElementById('modal-category-tag');
  const modalEventTitle = document.getElementById('modal-event-title');
  const modalDatetime = document.getElementById('modal-datetime');
  const modalVenue = document.getElementById('modal-venue');
  const modalOrganizer = document.getElementById('modal-organizer');
  const modalCapacity = document.getElementById('modal-capacity');
  const modalDesc = document.getElementById('modal-desc');
  const btnRegister = document.getElementById('btn-register-event');
  const btnSave = document.getElementById('btn-save-event');

  // Calendar configuration (April 2025 has 30 days; starts on Tuesday, meaning Sunday(30), Monday(31) are inactive from March)
  // Grid: 35 cells total (2 inactive from March, 30 active in April, 3 inactive in May)
  const renderCalendar = () => {
    calendarGrid.innerHTML = '';

    // Active Category Filters
    const checkedCategories = Array.from(categoryCheckboxes)
      .filter(cb => cb.checked)
      .map(cb => cb.value.toLowerCase());

    const searchQuery = globalSearchInput.value.trim().toLowerCase();

    // Days definition:
    // March 30, 31 (inactive)
    const daysConfig = [
      { day: 30, isInactive: true },
      { day: 31, isInactive: true }
    ];

    // April 1 to 30
    for (let i = 1; i <= 30; i++) {
      daysConfig.push({ day: i, isInactive: false });
    }

    // May 1, 2, 3 (inactive)
    daysConfig.push({ day: 1, isInactive: true });
    daysConfig.push({ day: 2, isInactive: true });
    daysConfig.push({ day: 3, isInactive: true });

    daysConfig.forEach(item => {
      const cell = document.createElement('div');
      cell.className = `day-cell ${item.isInactive ? 'inactive' : ''} ${item.day === 15 && !item.isInactive ? 'today' : ''}`;

      const numRow = document.createElement('div');
      numRow.className = 'day-number-row';

      const numEl = document.createElement('span');
      numEl.className = 'day-number';
      numEl.textContent = item.day;
      numRow.appendChild(numEl);
      cell.appendChild(numRow);

      const eventsStack = document.createElement('div');
      eventsStack.className = 'cell-events-stack';

      // Find events matching this active day
      if (!item.isInactive) {
        const dayEvents = EVENTS.filter(e => e.day === item.day);

        dayEvents.forEach(evt => {
          // Check Category Filter
          const catMatches = checkedCategories.length === 0 || checkedCategories.includes(evt.category.toLowerCase()) || checkedCategories.includes(evt.badgeClass.toLowerCase());

          // Check Search Filter
          const searchMatches = !searchQuery || evt.title.toLowerCase().includes(searchQuery) || evt.category.toLowerCase().includes(searchQuery) || evt.venue.toLowerCase().includes(searchQuery);

          if (catMatches && searchMatches) {
            const pill = document.createElement('div');
            pill.className = `event-pill ${evt.badgeClass}`;
            pill.innerHTML = `
              <span class="event-time-str">${evt.time}</span>
              <span class="event-title-str">${evt.title}</span>
            `;
            pill.addEventListener('click', (e) => {
              e.stopPropagation();
              openModal(evt);
            });
            eventsStack.appendChild(pill);
          }
        });
      }

      cell.appendChild(eventsStack);
      calendarGrid.appendChild(cell);
    });
  };

  // Render Upcoming Events List
  const renderUpcoming = () => {
    upcomingList.innerHTML = UPCOMING.map(item => `
      <div class="upcoming-item-card" data-title="${item.title}">
        <div class="upcoming-date-box ${item.colorClass}">
          <span class="day-val">${item.day}</span>
          <span class="month-val">${item.month}</span>
        </div>
        <div class="upcoming-details-block">
          <span class="upcoming-event-name">${item.title}</span>
          <span class="upcoming-time-range">${item.time}</span>
          <span class="upcoming-venue-text">${item.venue}</span>
        </div>
      </div>
    `).join('');

    upcomingList.querySelectorAll('.upcoming-item-card').forEach(card => {
      card.addEventListener('click', () => {
        const title = card.getAttribute('data-title');
        const evt = EVENTS.find(e => e.title === title) || {
          title,
          category: 'Workshop',
          time: '10:00 AM',
          day: 15,
          venue: 'Campus Hall',
          organizer: 'UniScout Guild',
          desc: 'Verified university campus engagement opportunity.'
        };
        openModal(evt);
      });
    });
  };

  // Modal actions
  const openModal = (evt) => {
    modalCategoryTag.textContent = evt.category;
    modalCategoryTag.className = `modal-category-tag ${evt.badgeClass || 'workshop'}`;
    modalEventTitle.textContent = evt.title;
    modalDatetime.textContent = `${evt.day} Apr 2025 • ${evt.time}`;
    modalVenue.textContent = evt.venue;
    modalOrganizer.textContent = evt.organizer || 'UniSZA Student Body';
    modalCapacity.textContent = '38 / 50 seats filled (12 remaining)';
    modalDesc.textContent = evt.desc || 'Comprehensive workshop exploring domain principles and hands-on skill development.';

    btnRegister.textContent = 'Register Now';
    btnRegister.style.backgroundColor = 'var(--primary-blue)';

    detailModal.classList.add('active');
  };

  const closeModal = () => {
    detailModal.classList.remove('active');
  };

  btnModalClose.addEventListener('click', closeModal);
  detailModal.addEventListener('click', (e) => {
    if (e.target === detailModal) closeModal();
  });

  btnRegister.addEventListener('click', () => {
    btnRegister.textContent = '✓ Registered!';
    btnRegister.style.backgroundColor = '#16a34a';
    setTimeout(closeModal, 800);
  });

  // Filter Listeners
  categoryCheckboxes.forEach(cb => {
    cb.addEventListener('change', renderCalendar);
  });

  btnClearCategories.addEventListener('click', () => {
    categoryCheckboxes.forEach(cb => cb.checked = false);
    renderCalendar();
  });

  globalSearchInput.addEventListener('input', renderCalendar);

  // View Segments
  viewSegments.forEach(btn => {
    btn.addEventListener('click', () => {
      viewSegments.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // Keyboard accessibility
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });

  // Initial Execution
  renderCalendar();
  renderUpcoming();

  // Multi-Screen Navigation Switching Logic (Covers ALL DFD Processes)
  const navLinks = document.querySelectorAll('[data-nav]');
  const viewPanels = document.querySelectorAll('.view-panel');
  const rightPanels = document.querySelectorAll('.sidebar-right-panel');

  const switchView = (targetNav) => {
    let viewId = 'view-' + targetNav;
    let rightPanelId = 'right-panel-' + targetNav;

    // Check if view element exists
    const targetView = document.getElementById(viewId);
    if (!targetView) return;

    // Update nav links active class
    navLinks.forEach(link => {
      if (link.getAttribute('data-nav') === targetNav) {
        link.classList.add('active');
      } else {
        link.classList.remove('active');
      }
    });

    // Update central view panels
    viewPanels.forEach(panel => {
      panel.classList.remove('active');
    });
    targetView.classList.add('active');

    // Update right sidebar panels
    rightPanels.forEach(panel => {
      panel.classList.remove('active');
    });
    const targetRightPanel = document.getElementById(rightPanelId);
    if (targetRightPanel) {
      targetRightPanel.classList.add('active');
    } else {
      const defaultRight = document.getElementById('right-panel-calendar');
      if (defaultRight) defaultRight.classList.add('active');
    }

    // Scroll to top of main workspace
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const targetNav = link.getAttribute('data-nav');
      if (targetNav) switchView(targetNav);
    });
  });

  // Top header profile dropdown trigger
  const topProfileBtn = document.getElementById('profile-dropdown-btn');
  if (topProfileBtn) {
    topProfileBtn.addEventListener('click', () => switchView('profile'));
  }

  // Edit Profile Modal Elements (Process 2.2)
  const editProfileModal = document.getElementById('edit-profile-modal');
  const btnOpenEditProfile = document.getElementById('btn-open-edit-profile');
  const btnEditProfileClose = document.getElementById('edit-profile-close');
  const btnSaveProfileChanges = document.getElementById('btn-save-profile-changes');

  if (btnOpenEditProfile && editProfileModal) {
    btnOpenEditProfile.addEventListener('click', () => {
      editProfileModal.classList.add('active');
    });
  }
  if (btnEditProfileClose && editProfileModal) {
    btnEditProfileClose.addEventListener('click', () => {
      editProfileModal.classList.remove('active');
    });
  }
  if (btnSaveProfileChanges && editProfileModal) {
    btnSaveProfileChanges.addEventListener('click', () => {
      alert('Profile updated successfully.');
      editProfileModal.classList.remove('active');
    });
  }

  // Cancel Registration Modal Elements (Process 4.2)
  const cancelRegModal = document.getElementById('cancel-reg-modal');
  const btnOpenCancelReg = document.getElementById('btn-open-cancel-modal');
  const btnConfirmCancelReg = document.getElementById('btn-confirm-cancel-reg');

  if (btnOpenCancelReg && cancelRegModal) {
    btnOpenCancelReg.addEventListener('click', () => {
      cancelRegModal.classList.add('active');
    });
  }
  if (btnConfirmCancelReg && cancelRegModal) {
    btnConfirmCancelReg.addEventListener('click', () => {
      alert('Registration successfully cancelled. Waitlist prioritized.');
      cancelRegModal.classList.remove('active');
    });
  }

  // Admin Sub-Tab Switching (Process 8.0)
  const adminTabBtns = document.querySelectorAll('[data-admin-tab]');
  const adminTabContents = document.querySelectorAll('.admin-tab-content');

  adminTabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      adminTabBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const target = btn.getAttribute('data-admin-tab');
      adminTabContents.forEach(content => {
        if (content.id === 'admin-tab-' + target) {
          content.style.display = 'block';
        } else {
          content.style.display = 'none';
        }
      });
    });
  });

  // Create Event Modal Open Trigger (Process 3.1 & 3.2)
  const btnOpenCreate = document.getElementById('btn-open-create-event');
  const createEventModal = document.getElementById('create-event-modal');
  if (btnOpenCreate && createEventModal) {
    btnOpenCreate.addEventListener('click', () => {
      createEventModal.classList.add('active');
    });
  }

  // Mark all read button trigger (Process 7.3)
  const btnMarkRead = document.getElementById('btn-mark-all-read');
  if (btnMarkRead) {
    btnMarkRead.addEventListener('click', () => {
      document.querySelectorAll('.unread-dot').forEach(d => d.style.display = 'none');
      alert('All notifications marked as read.');
    });
  }

  // Clear Bookmarks button trigger (Process 6.2)
  const btnClearBookmarks = document.getElementById('btn-clear-bookmarks');
  if (btnClearBookmarks) {
    btnClearBookmarks.addEventListener('click', () => {
      if (confirm('Clear all saved bookmarks?')) {
        document.querySelectorAll('.saved-card').forEach(c => c.style.display = 'none');
      }
    });
  }

  // Saved pill filter buttons (Process 6.3)
  const savedPillBtns = document.querySelectorAll('[data-saved-filter]');
  savedPillBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      savedPillBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const filter = btn.getAttribute('data-saved-filter');
      document.querySelectorAll('.saved-card').forEach(c => {
        if (filter === 'all' || c.getAttribute('data-category') === filter) {
          c.style.display = 'flex';
        } else {
          c.style.display = 'none';
        }
      });
    });
  });

});
